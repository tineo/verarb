class FechasDeEntrega < ActiveRecord::Base
  set_table_name "fechas_de_entrega"
  belongs_to :proyecto
  has_many :terminados_en_planta, { :class_name => "TerminadosEnPlanta" }
  
  
  def self.reset(project)
    FechasDeEntrega.destroy_all ["proyecto_id=?", project.id]
    return true
  end
  
  
  def can_be_defined?
  # A date can be DEFINED when it's a Project, as much as you want
    return false if self.proyecto.anulado?
    return false if self.proyecto.con_orden_de_trabajo?
    return true
  end
  
  
  def can_be_defined_by_executive?
    return false if self.pending?
    return false if self.awaiting_approval_op?
    return false if self.awaiting_modification_approval_op?
    return true
  end
  
  
  def can_be_defined_by_operations?
    return false if self.awaiting_approval_ex?
    return false if self.awaiting_modification_approval_ex?
    return true if self.pending?
    return true
  end
  
  
  def can_be_modified?
  # A date can be MODIFIED when it's an Order, with a password and stuff
    return false if self.proyecto.anulado?
    return false unless self.proyecto.con_orden_de_trabajo?
    return false unless [FECHAS_DE_ENTREGA_ACEPTADO, FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_EX,  FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_OP].include? self.estado
    return true
  end
  
  
  def accepted?
    return self.estado == FECHAS_DE_ENTREGA_ACEPTADO
  end
  
  
  def accepted!
    self.estado = FECHAS_DE_ENTREGA_ACEPTADO
    self.save
  end
  
  
  def pending?
    return self.estado == FECHAS_DE_ENTREGA_PENDIENTE
  end
  
  
  def awaiting_approval_ex?
    self.estado == FECHAS_DE_ENTREGA_POR_APROBAR_EX
  end
  
  
  def awaiting_approval_ex!
    self.estado = FECHAS_DE_ENTREGA_POR_APROBAR_EX
    self.save
  end
  
  
  def awaiting_approval_op?
    self.estado == FECHAS_DE_ENTREGA_POR_APROBAR_OP
  end
  
  
  def awaiting_approval_op!
    self.estado = FECHAS_DE_ENTREGA_POR_APROBAR_OP
    self.save
  end
  
  
  def awaiting_modification_approval_ex?
    self.estado == FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_EX
  end
  
  
  def awaiting_modification_approval_ex!
    self.estado = FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_EX
    self.save
  end
  
  
  def awaiting_modification_approval_op?
    self.estado == FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_OP
  end
  
  
  def awaiting_modification_approval_op!
    self.estado = FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_OP
    self.save
  end
  
  
   def awaiting_modification_approval?
     return self.awaiting_modification_approval_op? || self.awaiting_modification_approval_ex?
   end
  
  
  def status_to_s
    if FECHAS_DE_ENTREGA.keys.include? self.estado
      return FECHAS_DE_ENTREGA[self.estado]
    else
      raise "Fecha de Entrega #{self.id} has no known status!"
    end
  end
  
  
  def redefine_date!(d)
    self.fecha = d
    self.save
    
    return true
  end
  
  
  def modify_date!(d)
    if self.modification_asked_by_company?
      self.fecha_original = self.fecha if self.fecha_original.nil?
    else
      self.fecha_original = d
    end
    self.fecha = d
    self.save
    
    return true
  end
  
  
  def modification_asked_by_company?
    return self.mod_solicitado_por == "1"
  end
  
  
  def was_modified?
    return self.fecha_original != nil
  end
  
  
  def log(uid, comments)
    l = FechasDeEntregaLog.new({
      :fecha         => self.fecha,
      :proyecto_id   => self.proyecto_id,
      :user_id       => uid,
      :comentarios   => comments,
      :observaciones => self.observaciones
    })
    
    l.save
    
    return l
  end
  
  
  def modification_proposed_by_user
    return User.find(self.mod_propuesto_por_user)
  end
  
  
  def modification_solicited_by
    if self.mod_solicitado_por == "0"
      return "Cliente"
    else
      return "Empresa"
    end
  end
  
  
  def modification_proposed_by_area
    if self.mod_solicitado_por == "C"
      return "Comercial"
    else
      return "Operaciones"
    end
  end
  
  
  def finished_in_plant_quantity
    return 0 if self.terminados_en_planta.empty?
    return self.terminados_en_planta.inject(0) { |sum, e| sum + e.cantidad.to_i }
  end
  
  
  def quantity_in_guias
    c = GuiaDeRemision.find_by_sql "
      SELECT SUM(cantidad) AS total
        FROM guias_de_remisiones,
             guia_detalles
       WHERE guia_detalles.guia_de_remision_id=guias_de_remisiones.id
         AND fechas_de_entrega_id='#{self.id}'
         AND anulada='0'
         AND en_blanco='0'"
    return c.first.total.to_i
  end
  
  
  def quantity_available_for_guia
    t = self.finished_in_plant_quantity - self.quantity_in_guias
    raise "Fecha de Entrega (#{self.id}): Mismatch on available for Guia" if t < 0
    return t
  end
  
  
  def guias
    return GuiaDeRemision.find_by_sql("
      SELECT guias_de_remisiones.*
        FROM guias_de_remisiones,
             guia_detalles
       WHERE guia_detalles.guia_de_remision_id=guias_de_remisiones.id
         AND fechas_de_entrega_id='#{self.id}'
    ORDER BY serie, numero")
  end
  
  
  def active_guias
    return GuiaDeRemision.find_by_sql("
      SELECT guias_de_remisiones.*
        FROM guias_de_remisiones,
             guia_detalles
       WHERE guia_detalles.guia_de_remision_id=guias_de_remisiones.id
         AND fechas_de_entrega_id='#{self.id}'
         AND anulada='0'
         AND en_blanco='0'
    ORDER BY serie, numero")
  end
  
  
  def reporte_de_cumplimiento
    # Answer "false" if
    # - Has been modified by Operations
    # - Original date > now
    # - Entregado date > Original date
    
    return false if self.was_modified?
    
    real = self.proyecto.fecha_de_entrega_real
    real = real.to_time unless real.nil?
    
    if real.nil?
      return false if self.fecha > Time.now
    else
      return false if real > self.fecha
    end
    
    return true
  end
end

