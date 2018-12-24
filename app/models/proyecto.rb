class Proyecto < ActiveRecord::Base
  has_many :detalles
  belongs_to :opportunity
  belongs_to :contact
  belongs_to :account
  has_many :proyecto_estados, :order => "fecha DESC"
  has_one :area, { :class_name => "ProyectoArea" }
  has_many :mensajes, :order => "fecha"
  has_many :puntos_de_entrega, :order => "id"
  has_many :cotizaciones
  has_many :fechas_de_entrega, :order => "fecha"
  has_many :proyecto_fechas_de_entrega, :order => "created_on"
  has_many :op_date_redef, { :class_name => "ProyectoOPDateRedef", :order => "id" }
  has_one :op_fact_price_redef, { :class_name => "ProyectoFactPriceRedef" }
  has_many :grios, { :class_name => "GrioProyecto" }
  has_many :of, { :class_name => "OrdenesFacturas" }
  has_many :guias, { :class_name => "GuiaDeRemision", :order => "empresa, serie, numero" }
  has_many :nonvoid_guias, { :class_name => "GuiaDeRemision", :conditions => "guias_de_remisiones.anulada='0'", :order => "empresa, serie, numero" }
  has_many :notificaciones, { :class_name => "Notificacion", :order => "created_on" }
  
  #before_save :check_inmutable
  before_save :check_moneda_nil
  before_save :update_amounts
  before_save :update_fecha_de_entrega_odt
  before_save :update_last_factura
  after_save :do_this_after_save
  
  
  def do_this_after_save
    self.overwrite_crm_amount
    self.facturation_status
    self.billing_status
    self.update_fechas_de_entrega_status!
    
    #    unless @make_mutable || @make_inmutable
    #      if self.facturated_remainder == 0.00
    #        self.make_inmutable
    #      elsif self.facturated_remainder > 0.00
    #        self.make_mutable
    #      end
    #end
    
    return true
  end
  
  
  def update_last_factura
    if self.has_facturas_or_boletas? && self.facturated_remainder == 0.00
      self.fecha_cierre_odt = self.of.last.factura.fecha_emision
      self.odt_cerrada      = true
    else
      self.fecha_cierre_odt = nil
      self.odt_cerrada      = false
    end
    
    # Update my Facturas. IMPORTANT NOTE: we are using these special methods
    # because calling Facturas to be saved will do an infinite loop (when you
    # save a Factura, its ODTs are updated, which in turn update its Facturas,
    # which in turn updates its ODTs, which in turn... etc)
    # These methods skip the update of ODTs.
    if self.has_facturas_or_boletas?
      last_factura = self.of.last.factura
      
      self.of.each do |o|
        f = o.factura
        if f == last_factura
          f.mark_as_last_factura!
        else
          f.unmark_as_last_factura!
        end
      end
    end
    
    return true
  end
  
  
  def update_fecha_de_entrega_odt
    unless self.inmutable?
      if self.fechas_de_entrega.empty?
        date = nil
      else
        x = self.fechas_de_entrega.inject do |m, f| 
          if f.fecha > m.fecha 
            f
          else
            m
          end
        end
        date = x.fecha
      end
      
      self.fecha_de_entrega_odt = date
    end
  end
  
  
  def inmutable?
  # Temporal, until we fix this thing
    return false
  end
  
  
  def check_inmutable
    if @make_inmutable
      self.inmutable = true
    elsif @make_mutable
      self.inmutable = false
    elsif self.inmutable?
      raise "Record is inmutable"
      return false
    end
  end
  
  
  def update_amounts
    # Credit Notes
    r = OrdenesFacturas.find_by_sql "
      SELECT SUM(ordenes_facturas.monto_credito) AS monto_credito
        FROM ordenes_facturas,
             facturas
       WHERE facturas.id=ordenes_facturas.factura_id
         AND proyecto_id='#{self.id}'
         AND ignorar_descuento='0'
         AND facturas.anulada='0'"
    
    if r[0].monto_credito.nil?
      m = 0.00
    else
      m = r[0].monto_credito
    end
    
    self.monto_credito = m
    
    if self.monto_odt.nil?
      self.monto_activo = 0.00
    else
      self.monto_activo  = self.monto_odt - self.monto_credito
    end
    
    if m > 0.00
      self.con_nota_de_credito = true
    else
      self.con_nota_de_credito = false
    end
    
    # Monto Facturado
    r = OrdenesFacturas.find_by_sql "
      SELECT SUM(ordenes_facturas.monto_odt - ordenes_facturas.monto_credito) AS monto_activo
        FROM ordenes_facturas,
             facturas
       WHERE facturas.id=ordenes_facturas.factura_id
         AND proyecto_id='#{self.id}'
         AND facturas.anulada='0'"
    
    self.monto_facturado = r[0].monto_activo || 0.00
    
    return true
  end
  
  
  def make_inmutable
    @make_inmutable = true
    self.save
    @make_inmutable = nil
    return true
  end
  
  
  def make_mutable
    @make_mutable = true
    self.save
    @make_mutable = nil
    return true
  end
  
  
  def type
    if self.con_orden_de_trabajo?
      "o"
    else
      "p"
    end
  end
  
  
  def uid
  # URL ID. Read the code.
    if self.con_orden_de_trabajo?
      self.orden_id
    else
      self.id
    end
  end
  
  
  def self.find_odt(id)
    f = Proyecto.find_by_orden_id(id)
    
    if f.nil?
      raise ActiveRecord::RecordNotFound, "Couldn't find Order with ID=#{id}"
    else
      return f
    end
  end
  
  
  def executive
    return self.opportunity.executive
  end
  
  
  def account
    Account.find self.account_id
  end
  
  
  def nombre_proyecto
    self.opportunity.name
  end
  
  
  def init_status(uid)
    p = ProyectoEstado.new({
      :proyecto_id  => self.id,
      :estado       => E_NUEVO,
      :fecha        => Time.now,
      :user_id      => uid
    })
    
    p.save
    
    a                  = ProyectoArea.new
    a.proyecto_id      = self.id
    a.estado_ejecutivo = E_NUEVO
    a.save
  end
  
  
  def is_order?
    return self.con_orden_de_trabajo?
  end
  
  
  def can_create_cotizations?
    return self.con_orden_de_trabajo? == false
  end
  
  
  def reset_status(uid)
    if self.area.en_diseno?
      self.area.salida_diseno = nil
      if self.area.encargado_diseno == ""
        self.set_status E_DISENO_SIN_ASIGNAR, uid
      else
        self.set_status E_DISENO_EN_PROCESO, uid
      end
    end
    if self.area.en_planeamiento?
      self.area.salida_planeamiento = nil
      if self.area.encargado_planeamiento == ""
        self.set_status E_PLANEAMIENTO_SIN_ASIGNAR, uid
      else
        self.set_status E_PLANEAMIENTO_EN_PROCESO, uid
      end
    end
    if self.area.en_costos?
      self.area.salida_costos = nil
      self.set_status E_COSTOS_EN_PROCESO, uid
    end
#    if self.area.en_operaciones?
#      self.area.salida_operaciones = nil
#      self.set_status E_OPERACIONES_EN_PROCESO, uid
#    end
    
    self.area.update
  end
  
  
  def set_status(status, uid)
    p = ProyectoEstado.new({
      :proyecto_id  => self.id,
      :estado       => status,
      :fecha        => Time.now,
      :user_id      => uid
    })
    
    p.save
    
    # Gosh, I love this
    if [E_DISENO_EN_PROCESO, E_DISENO_SIN_ASIGNAR, E_DISENO_POR_APROBAR, E_DISENO_OBSERVADO, E_DISENO_APROBADO].include? status
      self.area.estado_diseno = status
    end
    
    if [E_PLANEAMIENTO_SIN_ASIGNAR, E_PLANEAMIENTO_EN_PROCESO, E_PLANEAMIENTO_POR_APROBAR, E_PLANEAMIENTO_OBSERVADO, E_PLANEAMIENTO_TERMINADO].include? status
      self.area.estado_planeamiento = status
    end
    
    if [E_COSTOS_EN_PROCESO, E_COSTOS_TERMINADO].include? status
      self.area.estado_costos = status
    end
    
    if [E_OPERACIONES_EN_PROCESO, E_OPERACIONES_POR_APROBAR_EX, E_OPERACIONES_POR_APROBAR_OP, E_OPERACIONES_TERMINADO, E_OPERACIONES_REDEF_WAITING_OP, E_OPERACIONES_REDEF_WAITING_EX].include? status
      self.area.estado_operaciones = status
    end
    
    if [E_INSTALACIONES_EN_PROCESO, E_INSTALACIONES_TERMINADO].include? status
      self.area.estado_instalaciones = status
    end
    
    # Always for the Exec (at least for now...)
    self.area.estado_ejecutivo = status
    
    self.area.update
    
    return true
  end
  
  
  def status
    if self.anulado?
      E_ANULADO
    elsif self.opportunity.sales_stage == "Closed Lost"
      E_PERDIDO
    elsif self.opportunity.sales_stage == "Closed Won"
      E_TERMINADO
    else
      self.area.estado_ejecutivo
    end
  end
  
  
  def active?
  # This verification should be removed
  #    if ["Closed Won", "Closed Lost"].include? self.opportunity.sales_stage
  #      return false
  #    else
      return true
  #    end
  end
  
  
  def current_area
    ProyectoArea.find :first, :conditions => ["proyecto_id=?", self.id], :order => "fecha_ingreso DESC"
  end
  
  
  def assign_to_diseno(uid)
    if self.disenador.empty?
      self.set_status E_DISENO_SIN_ASIGNAR, uid
    else
      self.set_status E_DISENO_EN_PROCESO, uid
    end
    
    self.en_diseno = "1"
    self.update
  end
  
  
  def assign_designer(uid)
    self.disenador = uid
    self.update
  end
  
  
  def self.total_en_fecha_de_entrega
    p = Proyecto.find_by_sql "SELECT * FROM proyectos WHERE fecha_entrega_diseno <= NOW()"
    return p.size
  end
  
  
  def self.total_en_fecha_de_entrega_ya_terminados
    p = Proyecto.find_by_sql "SELECT * FROM proyectos WHERE fecha_entrega_diseno <= NOW() AND terminado='1'"
    return p.size
  end
  
  
  def self.total_en_diseno
    p = Proyecto.find_by_sql "SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND en_diseno='1'"
    return p.size
  end
  
  
  def self.total_en_diseno_sin_asignar
    p = Proyecto.find_by_sql "SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND en_diseno='1' AND encargado_diseno=''"
    return p.size
  end
  
  
  def self.total_en_diseno_en_fecha_de_entrega
    p = Proyecto.find_by_sql "SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND en_diseno='1' AND fecha_entrega_diseno <= NOW() AND terminado='0'"
    return p.size
  end
  
  
  def self.total_en_planeamiento_por_entregar_hoy(uid)
    p = Proyecto.find_by_sql ["SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND en_planeamiento='1' AND encargado_planeamiento=? AND DATE_FORMAT(fecha_entrega_diseno, '%Y-%m-%d')=CURRENT_DATE", uid]
    return p.size
  end
  
  
  def self.total_en_planeamiento_en_proceso(uid)
    p = Proyecto.find_by_sql ["SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND en_planeamiento='1' AND encargado_planeamiento=? AND  estado_planeamiento='?'", uid, E_PLANEAMIENTO_EN_PROCESO]
    return p.size
  end
  
  
  def self.total_en_costos_por_entregar_hoy
    p = Proyecto.find_by_sql "SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND en_costos='1' AND DATE_FORMAT(fecha_entrega_diseno, '%Y-%m-%d')=CURRENT_DATE"
    return p.size
  end
  
  
  def self.total_en_costos_en_proceso
    p = Proyecto.find_by_sql ["SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND en_costos='1' AND  estado_costos='?'", E_COSTOS_EN_PROCESO]
    return p.size
  end
  
  
  def get_costs_files
    return FileList.new(self.costs_path)
  end
  
  
  def costs_path
    COSTS_PATH + self.id.to_s + "/"
  end
  
  
  def has_costs_files?
    return self.get_costs_files.empty? == false
  end
  
  
  def get_innovations_files
    return FileList.new(self.innovations_path)
  end
  
  
  def get_installations_files
    return FileList.new(self.installations_path)
  end
  
  
  def innovations_path
    INNOVATIONS_PATH + self.id.to_s + "/"
  end
  
  
  def installations_path
    INSTALLATIONS_PATH + self.id.to_s + "/"
  end
  
  
  def has_innovations_files?
    return self.get_innovations_files.empty? == false
  end
  
  
  def has_installations_files?
    return self.get_installations_files.empty? == false
  end
  
  
  def project_path
    # If you change this, update the new format on the path method of
    # the Detalle model
    PROJECTS_PATH + self.id.to_s + "/"
  end
  
  
  def in_danger?
    if self.fecha_entrega_diseno != nil && ((5.days.from_now >= self.fecha_entrega_diseno) || (Time.now > self.fecha_entrega_diseno)) && self.area.estado_diseno != E_DISENO_APROBADO
      return true
    end
    
    if self.fecha_entrega_planeamiento != nil && ((5.days.from_now >= self.fecha_entrega_planeamiento) || (Time.now > self.fecha_entrega_planeamiento)) && self.area.estado_planeamiento != E_PLANEAMIENTO_TERMINADO
      return true
    end
    
    if self.fecha_entrega_costos != nil && ((5.days.from_now >= self.fecha_entrega_costos) || (Time.now > self.fecha_entrega_costos)) && self.area.estado_costos != E_COSTOS_TERMINADO
      return true
    end
    
    return false
  end
  
  
  def self.orders_to_be_created(uid)
    ps = Proyecto.find_by_sql(
      "SELECT proyectos.*
         FROM proyectos,
              opportunities,
              proyecto_areas
        WHERE proyectos.opportunity_id=opportunities.id
          AND proyecto_areas.proyecto_id=proyectos.id
          AND proyectos.con_orden_de_trabajo='0'
          AND proyectos.anulado='0'
          " + (uid == :all ? "" : "AND opportunities.assigned_user_id='" + uid + "'") + "
          AND (    proyecto_areas.en_validacion_operaciones='1'
                OR
                   (proyecto_areas.en_operaciones='1'
                    AND proyecto_areas.estado_operaciones IN (#{E_OPERACIONES_POR_APROBAR_EX}, #{E_OPERACIONES_POR_APROBAR_OP})
                   )
              )
     ORDER BY opportunities.date_closed")
     
     return ps
  end
  
  
  def to_be_created_status
    if self.area.en_validacion_operaciones?
      return "Esperando Validaci&oacute;n"
    elsif self.area.en_operaciones?
      if self.area.estado_operaciones == E_OPERACIONES_POR_APROBAR_EX
        return "Pendiente por aprobar Ejecutivo"
      elsif self.area.estado_operaciones == E_OPERACIONES_POR_APROBAR_OP
        return "Pendiente por aprobar Operaciones"
      end
    end
    
    return ""
  end
  
  
  def can_be_promoted?(with_reason = nil)
    m = ""
    
    m += "<li> Tiene Orden de Trabajo" if self.con_orden_de_trabajo?
    m += "<li> La Oportunidad no est&aacute; marcada como Ganada" if self.opportunity.sales_stage != 'Closed Won'
    m += "<li> El Proyecto est&aacute; anulado" if self.anulado?
    m += "<li> El Dise&ntilde;o no ha sido aprobado" if self.area.en_diseno? && self.area.estado_diseno != E_DISENO_APROBADO
    m += "<li> Datos de Confirmaci&oacute;n no est&aacute;n completos" if self.datos_de_confirmacion_completos == false
    
    if with_reason
      return m
    else
      return m == ""
    end
  end
  
  
  def marked_cotization
    Cotizacion.find_by_proyecto_id_and_marked self.id, "1"
  end
  
  
  def monto_de_venta
    if self.monto_activo.nil?
      return 0.00
    else
      self.monto_activo
    end
  end
  
  
  def monto_odt_sin_igv
    return 0.00 if monto_odt.nil?
    
    if self.incluye_igv_odt?
      return (self.monto_odt / self.igv).round2
    else
      return self.monto_odt
    end
  end
  
  
  def monto_de_venta_sin_igv
    return 0.00 if monto_activo.nil?
    
    if self.incluye_igv_odt?
    # FIXME: IGV should not be here
      return (self.monto_activo / self.igv).round2
    else
      return self.monto_activo
    end
  end
  
  
  def monto_de_venta_as_soles
    monto = self.monto_de_venta_sin_igv
    
    if self.moneda_odt == "S"
      return monto
    else
      return (monto * self.tipo_de_cambio).round2
    end
  end
  
  
  def monto_de_venta_as_dollars
    monto = self.monto_de_venta_sin_igv
    
    if self.moneda_odt == "S"
      return (monto / self.tipo_de_cambio).round2
    else
      return monto
    end
  end
  
  
  def monto_de_oportunidad_as_dollars
    m = self.opportunity.amount
    
    if self.opportunity.currency_id == CRM_CURRENCY_SOLES
      return (m / self.tipo_de_cambio).round2
    else
      return m
    end
  end
  
  
  def self.full_list
    conditions = "opportunities.sales_stage IN ('Closed Won', 'Closed Lost') AND proyectos.anulado='0' AND NOT #{SQL_VERA_DELETED}"
    Proyecto.find :all, :include => [:opportunity], :conditions => conditions, :order => "proyectos.id"
  end
  
  
  def self.orders_full_list
    conditions = "proyectos.con_orden_de_trabajo='1' AND NOT #{SQL_VERA_DELETED}"
    Proyecto.find :all, :include => [:opportunity], :conditions => conditions, :order => "proyectos.orden_id"
  end
  
  
  def self.export_projects_list
    conditions = "proyecto_exportado=0"
    Proyecto.find :all, :include => [:opportunity], :conditions => conditions, :order => "proyectos.id"
  end
  
  
  def self.export_orders_list
    conditions = "proyectos.con_orden_de_trabajo='1' AND orden_exportada=0 AND inmutable='0'"
    Proyecto.find :all, :include => [:opportunity], :conditions => conditions, :order => "proyectos.orden_id"
  end
  
  
  def can_be_sent_to?(aid)
    if self.anulado?
      return false
    end
    
    if aid == A_DISENO
      if self.area.en_diseno? == false
        return true
      end
      
      if self.area.estado_diseno == E_DISENO_APROBADO
        return true
      end
      
      return false
    end
    
    if aid == A_PLANEAMIENTO
      if self.area.en_planeamiento? == false
        return true
      end
      
      if self.area.estado_planeamiento == E_PLANEAMIENTO_TERMINADO
        return true
      end
      
      return false
    end
    
    if aid == A_COSTOS
      if self.area.en_costos? == false
        return true
      end
      
      if self.area.estado_costos == E_COSTOS_TERMINADO
        return true
      end
      
      return false
    end
    
    if aid == A_OPERACIONES
      if self.can_be_promoted? == false
        return false
      end
      
      if self.area.en_validacion_operaciones?
        return false
      end
      
      if self.datos_de_confirmacion_completos? == false
        return false
      end
      
      if (self.area.en_operaciones? == false) || (self.area.en_operaciones? == true && self.area.estado_operaciones == E_OPERACIONES_TERMINADO && self.con_orden_de_trabajo? == false)
        return true
      end
      
      return false
    end
    
    if aid == A_INNOVACIONES
      if self.area.en_innovaciones? == false
        return true
      end
      
      return false
    end
    
    if aid == A_INSTALACIONES
      if self.area.en_instalaciones? == false
        return true
      end
      
      return false
    end
    
    return false
  end
  
  
  def overwrite_crm_amount
  # We've been asked to overwrite the amount of the CRM, because Vera will
  # always have the topmost precedence on ODT price
  # So we do this magically here, IF AND ONLY IF this Project is an Order
    if self.con_orden_de_trabajo?
      monto = self.monto_odt || 0.00
      
      self.opportunity.amount = self.monto_odt
      
      if self.moneda_odt == "S"
        currency = CRM_CURRENCY_SOLES
        # We also need to convert the thing over to amount_usdollar
        c = Currency.find(CRM_CURRENCY_SOLES).conversion_rate
        self.opportunity.amount_usdollar = monto / c
      else
        currency = CRM_CURRENCY_DOLARES
        # Since it's dollars, we copy the same value
        self.opportunity.amount_usdollar = monto
      end
      
      self.opportunity.currency_id = currency
      self.opportunity.save
    end
    
    return true
  end
  
  
  def self.aout(pid)
  # Removes a Project sent to Operations... they keep doing this.
    p = Proyecto.find pid
    
    p.area.en_operaciones      = false
    p.area.ingreso_operaciones = nil
    p.area.save
    
    return "ok"
  end
  
  
  def self.get_ventas_by_month(options = nil)
    # We have to fetch the data twice, once for Soles and then another pass
    # for Dollars.
    
    data = OHash.new
    
    data[2004] = [nil, 50130.49, 36316.06, 159122.5, 50598.37, 32709.34, 67931.02, 67070.69, 63974.11, 54367.31, 115581.91, 359740.82, 81675.07]
    
    data[2005] = [nil, 226649.65, 89690.75, 96621.07, 105616.83, 89612.54, 168722.71, 54632.80, 125112.27, 85330.49, 164749.20, 139712.03, 359740.82] 
    
    data[2006] = [nil, 113990.99, 54181.61, 108879.17, 94113.10, 140209.76, 187541.84, 175142.96, 101823.72, 215544.33, 125264.42, 365956.86, 95176.23]

    data[2007] = [nil, 101678.36, 157681.41, 178960.21, 159101.50, 274910.99, 172099.89, 225448.43, 207651.14, 216994.76, 220384.60, 398186.49, 135122.18]
    
    # We need the values as rounded ones, without decimals. Since I don't
    # want to mess with the data above, I iterate and round :\
    (2004..2007).each do |year|
      data[year].each_with_index do |v, i|
        data[year][i] = v.round unless v.nil?
      end
    end
    
    query = "SELECT proyectos.*
               FROM proyectos,
                    opportunities
              WHERE tipo_proyecto='#{T_NUEVO_PROYECTO}'
                AND fecha_creacion_odt >= '2008-01-01 00:00:00'
                AND empresa_vendedora <> #{TISAC}
                AND proyectos.con_orden_de_trabajo='1'
                AND proyectos.opportunity_id=opportunities.id
                AND NOT #{SQL_VERA_DELETED}
                AND opportunities.sales_stage='Closed Won'
                AND proyectos.anulado='0'"
    
    db = Proyecto.find_by_sql query
    
    db.each do |p|
      y  = p.fecha_creacion_odt.year
      
      if data[y].nil?
        data[y] = []
        
#        1.upto(12) do |m|
#          data[y][m] = 0.00
#        end
      end
      
      data[y][p.fecha_creacion_odt.month]  = 0.00 if data[y][p.fecha_creacion_odt.month].nil?
      data[y][p.fecha_creacion_odt.month] += p.monto_de_venta_as_dollars.round
    end
    
    if options == :return_cummulative
      # Month cummulative
      data.each do |i, months|
        a = 0.00
        
        months.each_with_index do |v, k|
          unless v.nil? || (i.to_i == Time.now.year && k > Time.now.month)
            v = v + a
            a = v
            
            data[i][k] = v
          end
        end
      end
    end
    
    return data
  end
  
  
  def self.get_account_movement_data(year, exec, tipo, sort_column, sort_direction)
    if exec == "-1"
      exec_query = ""
    else
      exec_query = "AND opportunities.assigned_user_id='" + exec + "'"
    end
    
    if tipo == "-1"
      tipo_query = ""
    else
      tipo_query = "AND proyectos.tipo_de_venta='" + tipo + "'"
    end
    
    # First we build a hash as an index of clients. This will help us
    # tabulate the values in order later.
    p = Account.find_by_sql "SELECT DISTINCT accounts.id,
                                             accounts.name
                                FROM proyectos,
                                     accounts,
                                     opportunities
                               WHERE proyectos.account_id=accounts.id
                                 AND proyectos.opportunity_id=opportunities.id
                                 AND YEAR(fecha_creacion_odt) IS NOT NULL
                                 AND tipo_proyecto=" + T_NUEVO_PROYECTO.to_s + "
                                 AND moneda_odt IN ('S', 'D')
                                 " + exec_query + "
                                 " + tipo_query + "
                            ORDER BY accounts.name"
    
    clients = {}
    
    p.each_with_index do |c, i|
      # By ID          index, name of the account
      clients[c.id] = [i, c.name]
    end
    
    # And here is our data array.
    # The structure is a bidimensional array. First dimension corresponds to
    # the index of the client as per the "clients" hash we just built.
    # Second dimension goes like this:
    #  [Rating, Executive name, Client Name
    # and then 13 columns, which correspond to 12 months + a Total
    
    data = []
    
    clients.each do |key, val|
      data[val[0]] = ["", "", val[1], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
    
    # After this, we populate/tabulate the data. Later, we sort it by whatever
    # field we want. Slower than doing it by SQL, but very, very flexible.
    
    # We fetch data several times for Soles/Dollars
    ["S", "D"].each do |currency|
      
      query = "SELECT accounts.name,
                      accounts.rating,
                      users.first_name,
                      users.last_name,
                      accounts.id AS account_id,
                      SUM(monto_activo) AS total,
                      MONTH(fecha_creacion_odt) AS month,
                      tipo_de_cambio.cambio AS tc
                 FROM proyectos,
                      accounts,
                      opportunities,
                      users,
                      tipo_de_cambio
                WHERE proyectos.account_id=accounts.id
                  AND proyectos.opportunity_id=opportunities.id
                  AND opportunities.assigned_user_id=users.id
                  AND YEAR(proyectos.fecha_creacion_odt)=YEAR(tipo_de_cambio.fecha)
              AND MONTH(proyectos.fecha_creacion_odt)=MONTH(tipo_de_cambio.fecha)
             AND  DAY(proyectos.fecha_creacion_odt)=DAY(tipo_de_cambio.fecha)
                  AND con_orden_de_trabajo='1'
                  AND tipo_proyecto=" + T_NUEVO_PROYECTO.to_s + "
                  AND moneda_odt=?
                  AND YEAR(fecha_creacion_odt)='" + year + "'
                  AND opportunities.sales_stage='Closed Won'
                  " + exec_query + "
                  " + tipo_query + "
             GROUP BY accounts.name, month"
             
             puts query
      
      db = Proyecto.find_by_sql [query, currency]
      
      db.each do |p|
        index = clients[p.account_id][0]
        tc    = p.tc.to_f
        
        # Find out the offset in which to write this value
        # See the structure of our table above to understand this code
        field = (p.month.to_i - 1) + 3
        
        if currency == "S"
          value = (p.total.to_f / tc).round
        else
          value = p.total.to_f.round
        end
        
        data[index][field] += value
        
        # We calculate the totals as we go
        data[index][-1] += value
        
        # And populate the Rating field of this client
        data[index][0] = p.rating
        
        data[index][1] = p.first_name.to_s
      end
    end
    
    # Here comes the nice part, sorting the mess.
    unless data.empty?
      if sort_column >= data[0].size
        sort_column = 0
      end
      
      data = data.sort do |a, b|
        x = a[sort_column]
        y = b[sort_column]
        
        # Special cases:
        if sort_column == 0
          x = "Z" if x.nil? || x.empty?
          y = "Z" if y.nil? || y.empty?
        
        # If it's by Executive (column index 1), we have to
        # sort in lowercase
        elsif sort_column == 1
          x = x.downcase
          y = y.downcase
        
        # Same for Client (column 2)
        elsif sort_column == 2
          x = x.downcase
          y = y.downcase
        end
        
        # if sort_direction == "0" we sort greater to lower. Opposite is "1".
        if sort_direction == "0"
          x <=> y
        else
          y <=> x
        end
      end
    end
    
    return data
  end
  
  
  def self.get_ventas_by_year
    data = Hash.new
    
    data[2004] = 1139217.69
    data[2005] = 1706191.16
    data[2006] = 1777824.99
    data[2007] = 2448219.96
    
    query = "SELECT *
               FROM proyectos,
                    opportunities
              WHERE proyectos.opportunity_id=opportunities.id
                AND tipo_proyecto='#{T_NUEVO_PROYECTO}'
                AND fecha_creacion_odt >= '2008-01-01 00:00:00'
                AND con_orden_de_trabajo='1'
                AND empresa_vendedora <> '#{TISAC}'
                AND proyectos.anulado='0'
                AND opportunities.sales_stage='Closed Won'
                AND NOT #{SQL_VERA_DELETED}"
    
    # Go Go Go
    db = Proyecto.find_by_sql query
    
    db.each do |p|
      year   = p.fecha_creacion_odt.year.to_i
      amount = p.monto_de_venta_as_dollars.round
      
      data[year]  = 0.00 unless data[year]
      data[year] += amount
    end
    
    return data
  end
  
  
  def self.get_commercial_briefing_data(which, start_month, start_year, end_month, end_year, sort, dir)
    
    if which == :groups
      # We build an index of Groups
      groups = Group.find :all, :order => "name"
      data   = []
      
      indexes = {}
      
      groups.each_with_index do |g, i|
        indexes[g.name] = i
        
        # And here is our data array.
        # The structure is a bidimensional array. First dimension corresponds
        # to the index as per the hash we are building.
        # Second dimension goes like this:
        #  [Name, Oportunidades, Vendido, Prospecto, Negociacion, Perdido,
        #  Meta, diferencia, productividad]
        data[i] = [g.name, 0, 0, 0, 0, 0, g.goal, 0, 0]
      end
    
    else
      # We build an index for Execs
      execs = User.list_of_executives_for_report
      data   = []
      
      indexes = {}
      
      execs.each_with_index do |u, i|
        indexes[u.full_name] = i
        
        # And here is our data array.
        # The structure is a bidimensional array. First dimension corresponds to
        # the index as per the hash we are building.
        # Second dimension goes like this:
        #  [Name, Oportunidades, Vendido, Prospecto, Negociacion, Perdido, Meta,
        #  diferencia, productividad]
        if u.cuota(Time.now)
          goal = u.cuota(Time.now).cuota
        else
          goal = 0
        end
        
        data[i] = [u.full_name, 0, 0, 0, 0, 0, goal, 0, 0]
      end
    end
    
    # Process the date range
    # Start Date
    if (start_month == "-1" && start_year != "-1")
      # He chose only year and no month, this means to consider
      # the start of the whole year
      start_date = start_year + "-01-01 00:00:00"
    elsif (start_month != "-1" && start_year != "-1")
      # He chose year and month
      start_date = start_year + "-" + start_month + "-01 00:00:00"
    else
      start_date = false
    end
    
    # End Date
    if (end_month == "-1" && end_year != "-1")
      # He chose only year and no month, this means to consider
      # the end of the whole year
      end_date = end_year + "-12-31 23:59:59"
    elsif (end_month != "-1" && end_year != "-1")
      # He chose year and month
      end_day  = Date.civil(end_year.to_i, end_month.to_i, -1).day.to_s.rjust(2, "0")
      end_date = end_year + "-" + end_month + "-" + end_day + " 23:59:59"
    else
      end_date = false
    end
    
    if start_date && end_date
      date_range = "AND opportunities.date_closed BETWEEN '#{start_date}' AND '#{end_date}'"
    
    elsif !start_date && end_date
      date_range = "AND opportunities.date_closed < '#{end_date}'"
    
    elsif start_date && !end_date
      date_range = "AND opportunities.date_closed > '#{start_date}'"
    
    else
      date_range = ''
    end
    
    if which == :groups
      sql = "SELECT opportunities.id,
                    groups.name AS name,
                    opportunities.sales_stage,
                    opportunities.amount,
                    opportunities.currency_id,
                    tipo_de_cambio.cambio
               FROM opportunities,
                    groups,
                    group_members,
                    tipo_de_cambio
              WHERE opportunities.assigned_user_id=group_members.user_id
                AND YEAR(date_entered)=YEAR(tipo_de_cambio.fecha)
                AND MONTH(date_entered)=MONTH(tipo_de_cambio.fecha)
                AND DAY(date_entered)=DAY(tipo_de_cambio.fecha)
                AND group_members.group_id=groups.id
                AND NOT #{SQL_VERA_DELETED}
                " + date_range
    else
      sql = "SELECT opportunities.id,
                    users.first_name,
                    users.last_name,
                    opportunities.sales_stage,
                    opportunities.amount,
                    opportunities.currency_id,
                    tipo_de_cambio.cambio
               FROM opportunities,
                    users,
                    tipo_de_cambio
              WHERE opportunities.assigned_user_id=users.id
                AND YEAR(opportunities.date_entered)=YEAR(tipo_de_cambio.fecha)
                AND MONTH(opportunities.date_entered)=MONTH(tipo_de_cambio.fecha)
                AND DAY(opportunities.date_entered)=DAY(tipo_de_cambio.fecha)
                AND NOT #{SQL_VERA_DELETED}
                " + date_range
    end
    
    db = Opportunity.find_by_sql sql
    
    db.each do |p|
      if which == :groups
        name = p.name
      else
        name = p.first_name + " " + p.last_name
      end
      
      index = indexes[name]
      
      unless index.nil?
        if p.currency_id == CRM_CURRENCY_SOLES
          amount = (p.amount.to_f / p.cambio.to_f).round
        else
          amount = p.amount.to_f.round
        end
        
        if p.sales_stage == 'Closed Won'
          data[index][2] += amount
          if which == :execs && name == "Carlos Diaz"
          end
        
        elsif p.sales_stage == 'Prospecting'
          data[index][3] += amount
        
        elsif p.sales_stage == 'Negotiation/Review' || p.sales_stage == 'requerim sin coti'
          data[index][4] += amount
        
        elsif p.sales_stage == 'Closed Lost'
          data[index][5] += amount
        end
      end
    end
    
    # Make the rest of the calcs
    data.each_with_index do |d, i|
      # Opportunities
      data[i][1] = data[i][2] + data[i][3] + data[i][4] + data[i][5]
      
      # Difference
      data[i][7] = data[i][2] - data[i][6]
      
      # Productivity
      if data[i][6] == 0
        data[i][8] = 0
      else
        data[i][8] = ((data[i][2] * 100) / data[i][6]).round
      end
    end
    
    # Sort, sort, sort
    if sort >= data[0].size
      sort = 0
    end
    
    data = data.sort do |a, b|
      x = a[sort]
      y = b[sort]
      
      # Special cases:
      if sort == 0
        # If it's by Client, we have to sort in lowercase
        x = x.downcase
        y = y.downcase
      end
      
      # if sort direction == "0" we sort greater to lower. Opposite is "1".
      if dir == "0"
        x <=> y
      else
        y <=> x
      end
    end
    
    return data
  end
  
  
  def self.get_commercial_briefing_data_ratios(start_month, start_year, end_month, end_year, sort, dir)
    # We build an index for Execs
    execs  = User.list_of_executives_for_report
    data   = []
    buffer = []
    accts  = []
    
    indexes = {}
    
    execs.each_with_index do |u, i|
      indexes[u.id] = i
      
      # We fetch the total number of Accounts this user has assigned.
      # We need this data for the Rotacion.
      total_accounts = User.find_by_sql("SELECT COUNT(*) AS total FROM accounts WHERE assigned_user_id='" + u.id + "'")[0].total.to_i
      
      # And here is our data array.
      # The structure is a bidimensional array. First dimension corresponds to
      # the index as per the hash we are building.
      # Second dimension goes like this:
      #  [Name, Efectividad Cierre, Efectividad Venta, Rotacion]
      data[i]   = [u.full_name, 0, 0, total_accounts]
      buffer[i] = [u.full_name, 0, 0, 0]
    end
    
    # Process the date range
    # Start Date
    if (start_month == "-1" && start_year != "-1")
      # He chose only year and no month, this means to consider
      # the start of the whole year
      start_date = start_year + "-01-01 00:00:00"
    elsif (start_month != "-1" && start_year != "-1")
      # He chose year and month
      start_date = start_year + "-" + start_month + "-01 00:00:00"
    else
      start_date = false
    end
    
    # End Date
    if (end_month == "-1" && end_year != "-1")
      # He chose only year and no month, this means to consider
      # the end of the whole year
      end_date = end_year + "-12-31 23:59:59"
    elsif (end_month != "-1" && end_year != "-1")
      # He chose year and month
      end_day  = Date.civil(end_year.to_i, end_month.to_i, -1).day.to_s.rjust(2, "0")
      end_date = end_year + "-" + end_month + "-" + end_day + " 23:59:59"
    else
      end_date = false
    end
    
    if start_date && end_date
      date_range = "AND opportunities.date_entered BETWEEN '#{start_date}' AND '#{end_date}'"
    
    elsif !start_date && end_date
      date_range = "AND opportunities.date_entered < '#{end_date}'"
    
    elsif start_date && !end_date
      date_range = "AND opportunities.date_entered > '#{start_date}'"
    
    else
      date_range = ''
    end
    
    # First stage: gather the totals and the Closed Wons
    ['S', 'D'].each do |currency|
      if currency == 'S'
        currency_id = CRM_CURRENCY_SOLES
      else
        currency_id = CRM_CURRENCY_DOLARES
      end
      
      sql = "SELECT users.id AS user_id,
                    opportunities.sales_stage,
                    COUNT(*) AS number,
                    SUM(opportunities.amount) AS total,
                    opportunities.currency_id,
                    tipo_de_cambio.cambio
               FROM opportunities,
                    users,
                    tipo_de_cambio
              WHERE opportunities.assigned_user_id=users.id
                AND YEAR(opportunities.date_entered)=YEAR(tipo_de_cambio.fecha)
                AND MONTH(opportunities.date_entered)=MONTH(tipo_de_cambio.fecha)
                AND DAY(opportunities.date_entered)=DAY(tipo_de_cambio.fecha)
                AND NOT #{SQL_VERA_DELETED}
                AND users.deleted='0'
                AND users.status='Active'
                AND opportunities.sales_stage IN ('Closed Won', 'Prospecting', 'Negotiation/Review', 'requerim sin coti', 'Closed Lost')
                AND currency_id='" + currency_id + "'
                " + date_range + "
           GROUP BY users.id"
      
      db = Proyecto.find_by_sql sql
      
      db.each do |p|
        index = indexes[p.user_id]
        
        unless index.nil?
          if currency == 'S'
            amount = (p.total.to_f / p.cambio.to_f).round
          else
            amount = p.total.to_f.round
          end
          
          data[index][1] += p.number.to_i
          data[index][2] += amount
          
          if p.sales_stage == 'Closed Won'
            buffer[index][1] += p.number.to_i
            buffer[index][2] += amount
          end
        end
      end
    end
    
    # Now the data for Rotacion
    sql = "SELECT users.id AS user_id,
                  COUNT(DISTINCT account_id) AS number
             FROM opportunities,
                  users,
                  accounts_opportunities
            WHERE opportunities.assigned_user_id=users.id
              AND accounts_opportunities.opportunity_id=opportunities.id
              AND accounts_opportunities.deleted='0'
              AND NOT #{SQL_VERA_DELETED}
              AND users.deleted='0'
              AND users.status='Active'
              AND opportunities.sales_stage IN ('Closed Won', 'Prospecting', 'Negotiation/Review', 'requerim sin coti', 'Closed Lost')
              " + date_range + "
         GROUP BY assigned_user_id"
    
    db = Proyecto.find_by_sql sql
    
    db.each do |p|
      index = indexes[p.user_id]
      
      buffer[index][3] = p.number.to_i unless index.nil?
    end
    
    # We now have the totals in 'data' and the Closed Wons in 'buffer'
    # Let's process it now. Everything will be saved in 'data'.
    data.each_with_index do |d, i|
      (1..3).each do |x|
        if data[i][x] == 0
          data[i][x] = 0
        else
#          data[i][x] = buffer[i][x].to_s + " / " + data[i][x].to_s
          data[i][x] = ((buffer[i][x] * 100) / data[i][x]).round
        end
      end
    end
    
    # The trivial part (thanks to Ruby): the sort
    if sort >= data[0].size
      sort = 0
    end
    
    data = data.sort do |a, b|
      x = a[sort]
      y = b[sort]
      
      # Special cases:
      if sort == 0
        # If it's by Client, we have to sort in lowercase
        x = x.downcase
        y = y.downcase
      end
      
      # if sort direction == "0" we sort greater to lower. Opposite is "1".
      if dir == "0"
        x <=> y
      else
        y <=> x
      end
    end
    
    return data
  end
  
  
  def self.get_new_order_id
    o = OrdenID.new
    o.save
    
    return o.id
  end
  
  
  def has_related_grios?
    self.grios.size > 0
  end
  
  
  def is_a_grio?
    if GrioProyecto.find_by_grio_id self.id
      return true
      # WHY DID WE DID THIS?
      #    elsif self.opportunity.used_in_vera? 
      #      return true
    else
      return false
    end
  end
  
  
  def get_parent_project
  # If this project is a Garant�a/Reclamo, then this method returns its
  # parent Project.
    p = GrioProyecto.find_by_grio_id self.id
    
    if p
      return Proyecto.find(p.proyecto_id)
    else
      return false
    end
  end
  
  
  def tipo_de_cambio
    if self.con_orden_de_trabajo?
      fecha = self.fecha_creacion_odt
    else
      fecha = self.fecha_creacion_proyecto
    end
    
    tc = TipoDeCambio.find_by_fecha fecha.beginning_of_day
    
    if tc
      return tc.cambio
    else
      return 1.00
    end
  end
  
  
  def quantity_of_approved_products
    details = Detalle.get_all_approved_of_project(self.id)
    
    total_products = 0
    
    details.each do |d|
      total_products = total_products + d.cantidad if d.tipo == "P"
    end
    
    return total_products
  end
  
  
  def update_adelanto_status
  # Updates the adelanto of a series of Facturas which belong to an Order.
    ofs = OrdenesFacturas.find_by_sql "SELECT ordenes_facturas.* FROM ordenes_facturas, facturas WHERE ordenes_facturas.factura_id=facturas.id AND ordenes_facturas.proyecto_id='#{self.id}' AND facturas.anulada='0' AND facturas.en_blanco='0' ORDER BY facturas.fecha_emision";
    
    unless ofs.empty?
      # First, nobody has adelanto! I said!
      ofs.each do |o|
        o.adelanto = false
        o.save
      end
      
      # Then, if the ODT has adelanto, then we mark the first one as such
      if self.con_adelanto?
        ofs.first.adelanto = true
        ofs.first.save
      end
    end
    
    return true
  end
  
  
  def con_adelanto?
    return monto_adelanto != 0.00
  end
  
  
  def monto_facturado_as_soles
    monto = self.monto_facturado
    
    if self.moneda_odt == "S"
      return monto
    else
      return (monto * self.tipo_de_cambio).round2
    end
  end
  
  
  def monto_facturado_as_dollars
    monto = self.monto_facturado
    
    if self.moneda_odt == "D"
      return monto
    else
      return (monto / self.tipo_de_cambio).round2
    end
  end
  
  
  def has_facturas?
    return self.facturas.empty? == false
  end
  
  
  def has_facturas_or_boletas?
    return false if self.of.empty?
    has = false
    
    self.of.each do |of|
      has = true unless of.factura.anulada?
    end
    
    return has
  end
  
  
  def facturation_status
    if self.tipo_proyecto != T_NUEVO_PROYECTO
      return TIPO_PROYECTO[self.tipo_proyecto]
    elsif self.anulado?
      return "Anulado"
    end
    
    if self.of.empty?
      of = []
    else
      of = self.of.select { |f| !f.factura.anulada? }
    end
    
    if of.empty?
      sf = F_POR_FACTURAR
    elsif self.facturated_remainder > 0.00
      sf = F_FACTURA_PARCIAL
    elsif self.facturated_remainder == 0.00
      sf = F_FACTURA_TOTAL
    end
    
    unless self.inmutable? || self.status_facturacion == sf
      self.status_facturacion = sf
      self.save
    end
    
    return ODT_STATUS_FACTURACION[sf]
  end
  
  
  def billing_status
    return true if self.inmutable?
    
    if self.tipo_proyecto != T_NUEVO_PROYECTO
      return TIPO_PROYECTO[self.tipo_proyecto]
    elsif self.anulado?
      return "Anulado"
    end
    
    if self.billed_remainder == 0.00
      sc = C_COBRADO
    else
      sc = C_POR_COBRAR
    end
    
    unless self.status_cobranza == sc
      self.status_cobranza = sc
      self.save
    end
    
    return ODT_STATUS_COBRANZA[sc]
  end
  
  
  def monto_cobrado
    r = OrdenesFacturas.find_by_sql "
      SELECT SUM(ordenes_facturas.monto_activo) AS monto_activo
        FROM ordenes_facturas,
             facturas
       WHERE facturas.id=ordenes_facturas.factura_id
         AND proyecto_id='#{self.id}'
         AND facturas.anulada='0'
         AND facturas.cobrada='1'"
    
    return r[0].monto_activo || 0.00
  end
  
  
  def cobrado?
    return false if self.monto_cobrado == 0.00
    return self.monto_de_venta_sin_igv == self.monto_cobrado
  end
  
  
  def cobrada?
    return self.cobrado?
  end
  
  
  def facturas
    return OrdenesFacturas.find_by_sql("SELECT ordenes_facturas.* FROM ordenes_facturas, facturas WHERE ordenes_facturas.proyecto_id='#{self.id}' AND facturas.id=ordenes_facturas.factura_id AND facturas.tipo='F' ORDER BY facturas.fecha_emision")
  end
  
  
  def boletas
    return OrdenesFacturas.find_by_sql("SELECT ordenes_facturas.* FROM ordenes_facturas, facturas WHERE ordenes_facturas.proyecto_id='#{self.id}' AND facturas.id=ordenes_facturas.factura_id AND facturas.tipo='B'")
  end
  
  
  def most_recent_factura_date
    newest = 100.years.ago
    
    self.facturas.each do |of|
      f = of.factura
      
      if f.fecha_emision > newest
        newest = f.fecha_emision
      end
    end
    
    return newest
  end
  
  
  def is_facturable?(with_motive = nil)
    motive = ""
    
    motive = "No est&aacute; autorizada para Facturar" unless self.autorizado_para_facturar?
    motive = "No es de tipo \"Nuevo Proyecto.\"" unless self.tipo_nuevo_proyecto?
    motive = "Est&aacute; anulada" if self.anulado?
    motive = "Ha sido facturada por completo" if self.facturated_remainder <= 0
    motive = "El monto ha sido cambiado y est&aacute; pendiente de autorizar" if self.facturated_price_redefined? == false
    
    # Finally
    if with_motive
      return motive
    else
      return motive == ""
    end
  end
  
  
  def can_have_guias?(with_motive = nil)
    motive = ""
    
    motive = "La Orden est&aacute; anulada" if self.anulado?
    motive = "La &uacute;ltima Gu&iacute;a ya fue ingresada" if self.con_guias_completas?
    motive = "No hay productos disponibles en planta" if self.quantity_available_for_guia == 0
    
    # Finally
    if with_motive.nil?
      return (motive == "" ? true : false)
    else
      return motive
    end
  end
  
  
  def facturated_remainder
    return (self.monto_odt_sin_igv - self.monto_facturado).round2
  end
  
  
  def facturated_remainder_as_soles
    monto = self.facturated_remainder
    
    if self.moneda_odt == "S"
      return monto
    else
      return (monto * self.tipo_de_cambio).round2
    end
  end
  
  
  def facturated_remainder_as_dollars
    monto = self.facturated_remainder
    
    if self.moneda_odt == "D"
      return monto
    else
      return (monto / self.tipo_de_cambio).round2
    end
  end
  
  
  def billed_remainder
    return (self.monto_de_venta_sin_igv - self.monto_cobrado).round2
  end
  
  
  def self.change_type(pid, type, t = :odt)
  # Convenience method for me, since Luz keeps often requests these changes.
    if t == :odt
      p = Proyecto.find_odt pid
    else
      p = Proyecto.find pid
    end
    
    p.tipo_proyecto = type
    
    if type == T_NUEVO_PROYECTO
      p.opportunity.deleted      = 0
      p.opportunity.used_in_vera = 0
    else
      p.opportunity.deleted      = 1
      p.opportunity.used_in_vera = 1
    end
    
    p.opportunity.save
    p.save
  end
  
  
  def confirmation_docs_path
    DOCS_PATH + self.id.to_s + "/"
  end
  
  
  def get_confirmation_docs
    p = self.confirmation_docs_path
    FileUtils.mkdir(p) unless File.exists?(p)
    
    return FileList.new(p)
  end
  
  
  def has_confirmation_docs?
    return self.get_confirmation_docs.empty? == false
  end
  
  
  def tipo_nuevo_proyecto?
    return self.tipo_proyecto == T_NUEVO_PROYECTO
  end
  
  
  def payment_form
    return "" unless self.facturation_data_complete?
    
    if self.factura_contraentrega?
      return "Contraentrega"
    else
      return "A #{self.dias_plazo} d&iacute;as"
    end
  end
  
  
  def dias_plazo_as_number
    if self.factura_contraentrega?
      return 0
    else
      return self.dias_plazo.to_i
    end
  end
  
  
  def facturation_data_complete?
  # Checks if all fields for facturation are there
    return false if self.factura_contraentrega.nil? && self.dias_plazo.nil?
    return false unless self.has_confirmation_docs?
    return false unless factura_razon_social
    return false unless factura_ruc
    return false if factura_fecha_facturacion.nil?
    return false if factura_descripcion == ""
    return false if factura_contacto_facturacion == ""
    return false if factura_telefono_fijo == "" && factura_telefono_movil == ""
    return false if factura_direccion == ""
    return false if self.moneda_odt == "" && self.tipo_nuevo_proyecto?
    
    # "No, Mister Bond, I want you to die"
    return true
  end
  
  
  def transform_to_grio(oid, type)
  # Makes an existing project a GRIO of another one
    return false if self.has_related_grios?
    
    order = Proyecto.find_odt oid
    
    self.tipo_proyecto = type
    self.otro_tipo     = ""
    self.save
    
    ref             = GrioProyecto.new
    ref.proyecto_id = order.id
    ref.grio_id     = self.id
    ref.save
    
    return true
  end
  
  
  def active_guias
  # Returns all Guias which aren't voided
    return self.guias.select do |guia|
      guia.anulada? == false
    end
  end
  
  
  def factura_account
    return nil if self.factura_account_id.nil? || self.factura_account_id.empty?
    return Account.find(self.factura_account_id)
  end
  
  
  def factura_razon_social
    if self.factura_account.nil?
      super
    else
      self.factura_account.name
    end
  end
  
  
  def factura_ruc
    if self.factura_account.nil?
      super
    else
      self.factura_account.ruc
    end
  end
  
  
  def por_facturar?
    return self.status_facturation.to_s == F_POR_FACTURAR
  end
  
  
  def factura_parcial?
    return self.status_facturacion.to_s == F_FACTURA_PARCIAL
  end
  
  
  def facturado?
    return self.status_facturacion == F_FACTURA_TOTAL
  end
  
  
  def last_guia
    g = GuiaDeRemision.find_by_sql "
      SELECT *
        FROM guias_de_remisiones
       WHERE proyecto_id='#{self.id}'
         AND anulada='0'
         AND en_blanco='0'
         AND ultima_guia='1'
    ORDER BY fecha_emision DESC"
    
    if g.empty?
      return nil
    else
      return g.first
    end
  end
  
  
  def con_guias_completas?
    return self.last_guia != nil
  end
  
  
  def fecha_de_entrega_real
    if self.con_guias_completas?
      return self.last_guia.fecha_despacho
    else
      return nil
    end
  end
  
  
  def status_de_entrega_total
    if self.con_guias_completas?
      return "1"
    else
      return "0"
    end
  end
  
  
  def check_moneda_nil
    raise "MONEDA_NIL #{self.id}" if self.con_orden_de_trabajo? && self.moneda_odt == nil && !self.is_a_grio?
  end
  
  
  def with_fecha_de_entrega_modified?
    return self.op_date_redef.size > 0
  end
  
  
  def archive
    self.opportunity.sales_stage = 'Closed Lost'
    self.opportunity.save
    return true
  end
  
  
  def current_op_date_redef
  # Returns the most current redefinition of Fecha de Entrega with Operaciones
    r = ProyectoOPDateRedef.find_by_sql "SELECT * FROM proyecto_op_date_redef WHERE proyecto_id='#{self.id}' ORDER BY id DESC LIMIT 1"
    
    if r.nil?
      return nil
    else
      return r[0]
    end
  end
  
  
  def each_sispre_insumo
    # A block/closure/whatever to iterate for each insumo
    tc = SispreTipoCambio.get_venta_for_today
    
    # Basically, we iterate the Insumos which were freed (salida) for this ODT
    salidas  = SalidaDetalle.find_all_by_Cod_OT self.orden_id
    
    salidas.each do |s|
      # Get the most recent price
      insumo = (InsumoItem.find_by_sql "SELECT * FROM mt_Insumos_Proveedores WHERE Cod_ins='#{s.insumo.id}' ORDER BY Fecha_Compra DESC LIMIT 1").first
      
      if insumo.nil?
        dollars = soles = costo = total = 0.00
      else
        p = insumo.Precio_Ins.to_f
        
        # Conversions
        if insumo.Moneda_Ins == "D"
          dollars = (p / self.igv).round3
          soles   = ((p * tc) / self.igv).round3
        else
          dollars = ((p / tc) / self.igv).round3
          soles   = (p / self.igv).round3
        end
        
        costo = dollars
        total = s.Cant_Sal * costo
      end
      
      yield(s, dollars, soles, costo, total)
    end
  end
  
  
  def each_sispre_service
    # A block/closure/whatever to iterate for each service
    services = ServicioItem.find_by_sql "
      SELECT pt_Servicios_Items.*,
             Tipo_Cambio
        FROM pt_Servicios_Items,
             pt_Servicios_Cabecera
       WHERE pt_Servicios_Items.cod_servicio=pt_Servicios_Cabecera.cod_servicio
         AND Cod_OT='#{self.orden_id}'
         AND pt_Servicios_Cabecera.anula_servicio='N'"
         
    
    services.each do |s|
      if s.Moneda == 'S'
        costo = s.Precio / (s.Tipo_Cambio).to_f
      else
        costo = s.Precio
      end
      
      costo = costo / self.igv
      
      total = s.Cantidad * costo
      
      yield(s, costo, total)
    end
  end
  
  
  def each_sispre_compras_libres
    # A block/closure/whatever to iterate for each service
    compras = ComprasLibresCabecera.find_by_sql "
      SELECT c.* 
        FROM pt_Compras_Libres_Cabecera AS c,
             pt_Compras_Libres_Detalle AS d
       WHERE d.cod_compra=c.cod_compra
         AND d.cod_ot='#{self.orden_id}'
    ORDER BY c.cod_tipodoc"
      
    compras.each do |c|
      if c.Moneda == 'S'
        tc    = SispreTipoCambio.get_for_date(c.Fecha_Ingreso).Venta_Tip.to_f.round3
        total = c.Total / tc
      else
        total = c.Total
      end
      
      # IGV
      total = total / self.igv unless c.IGV.to_f == 0.00
      
      yield(c, total)
    end
  end
  
  
  def variable_cost
    total = total_sispre_insumos + total_sispre_servicios + total_sispre_compras_libres
    
    # Update field
    unless self.inmutable?
      self.costo_variable = total
      self.save
    end
    
    return total
  end
  
  
  def total_sispre_insumos
    t = 0.00
    
    each_sispre_insumo do |s, dollars, soles, cost, total|
      t += total
    end
    
    return t.round2
  end
  
  
  def total_sispre_servicios
    t = 0.00
    
    each_sispre_service do |s, cost, total|
      t += total
    end
    
    return t.round2
  end
  
  
  def total_sispre_compras_libres
    t = 0.00
    
    each_sispre_compras_libres do |s, total|
      t += total
    end
    
    return t.round2
  end
  
  
  def monto_de_venta_sispre
    if self.moneda_odt == 'S'
      tc = SispreTipoCambio.get_venta_for_today
      return self.monto_de_venta_sin_igv / tc
    else
      return self.monto_de_venta_sin_igv
    end
  end
  
  
  def export_project_to_file
    return true if self.proyecto_exportado?
    
    p = self
    
    if p.fecha_entrega_costos.nil?
      fecha_entrega_costos = ""
    else
      fecha_entrega_costos = p.fecha_entrega_costos.strftime("%d/%m/%Y")
    end
    
    if p.opportunity.currency_id == CRM_CURRENCY_SOLES
      moneda = "S"
    else
      moneda = "D"
    end
    
    if p.account.billing_address_street.nil?
      address = ""
    else
      address = p.account.billing_address_street.gsub(/\r\n/, " ")
      address = address.gsub(/\n/, " ")
    end
    
    if p.opportunity.name.nil?
      description = ""
    else
      description = p.opportunity.name.gsub(/\n/, " ")
    end
    
    if p.account.sic_code.nil? || p.account.sic_code == ""
      ruc = ""
    else
      ruc = p.account.sic_code
    end
    
    if p.opportunity.amount.nil?
      amount = 0
    else
      amount = p.opportunity.amount
    end
    
    # Sacamos la cantidad de productos
    cantidad = 0
    
    p.detalles.each do |d|
      cantidad = cantidad + d.cantidad
    end
    
    s = p.id.to_s.pad(10) +
        p.fecha_creacion_proyecto.strftime("%d/%m/%Y").pad(10) +
        ruc.to_s.pad(11) +
        p.account.name.pad(50) +
        address.pad(100) +
        (" %.2f" % amount).pad(10) +
        moneda.pad(1) +
        description.pad(50) + # ?
        fecha_entrega_costos.pad(10) +
        p.executive.user_name.pad(25) +
        cantidad.to_s.pad(10) +
        EMPRESA_VENDEDORA_RUC[p.empresa_vendedora].pad(11) +
        ""
    
    f = File.open(BUDGET_EXPORT_PATH + "P" + p.id.to_s.rjust(10, "0") + ".txt", "w")
    f.print s
    f.close
    
    p.proyecto_exportado = true
    p.save
  end
  
  
  def set_account_to(aid)
    m = p.inmutable?
    
    p.make_mutable if m
    p.account_id = aid
    p.save
    p.opportunity.set_account_to aid
    p.make_inmutable if m
    
    return true
  end
  
  
  def self.calculate_executives_quotas(date, tisac, executive = nil)
    conditions = "opportunities.sales_stage IN ('Closed Won', 'Closed Lost') AND proyectos.con_orden_de_trabajo='1' AND NOT #{SQL_VERA_DELETED} AND proyectos.anulado='0' AND proyectos.tipo_proyecto='#{T_NUEVO_PROYECTO}' "
    
    if tisac == "0"
      conditions += " AND empresa_vendedora <> '#{TISAC}' "
    end
      
    end_date = Time.mktime(date.year, date.month, Date.civil(date.year, date.month, -1).day, 23, 59, 59)
      
    conditions = conditions + " AND fecha_creacion_odt BETWEEN '#{date.year}-#{date.month}-01 00:00:00' AND '#{end_date.year}-#{end_date.month}-#{end_date.day} 23:59:59'"
    
    conditions = conditions + " AND opportunities.assigned_user_id='" + executive + "'" unless executive == nil
    
    # Ok, here we go!
    projects = Proyecto.find :all, :include => [:area, :opportunity], :conditions => conditions
      
    exec_data       = []
    exec_buffer     = {}
    
    projects.each do |p|
      monto_soles     = p.monto_de_venta_as_soles.round
      monto_dolares   = p.monto_de_venta_as_dollars.round
      
      exec_buffer[p.executive.id] ||= self.new_exec_item(p.executive, date)
      
      exec_buffer[p.executive.id][:sold]      += monto_dolares
      exec_buffer[p.executive.id][:sold_odts] << p
      
      if p.account.cobranza_larga? || p.cobrada?
        exec_buffer[p.executive.id][:billed] += monto_dolares
        exec_buffer[p.executive.id][:billed_odts] << p
      else
        exec_buffer[p.executive.id][:unbilled_odts] << p
      end
      
      if p.has_facturas_or_boletas?
        exec_buffer[p.executive.id][:facturated] += p.monto_facturado_as_dollars.round
        exec_buffer[p.executive.id][:facturated_odts] << p
      else
        exec_buffer[p.executive.id][:unfacturated_odts] << p
      end
      
      exec_buffer[p.executive.id][:total_odt] += 1
    end
    
    # Ok, now we parse the comissions table
    if date > Time.mktime(2008, 10, 30, 23, 59, 59)
      cc = ComisionesCabecera.comissions_for(date)
      
      cc.each do |c|
        u = c.user
        exec_buffer[u.id] ||= self.new_exec_item(u, date)
        
        exec_buffer[u.id][:comission] += c.monto
      end
    end
    
    # Now, the definitive exec table
    exec_buffer.each do |id, e|
      name           = e[:user].full_name
      sold           = e[:sold]
      quota          = e[:quota]
      bonus          = e[:bonus]
      comission_rate = e[:comission_rate]
      billed         = e[:billed]
      facturated     = e[:facturated]
      comission      = e[:comission]
      total_odt      = e[:total_odt]
      
      diff        = sold - quota
      billed_diff = billed -quota
      
      if quota > 0
        productivity = ((sold * 100) / quota).round
      else
        productivity = 0
      end
      
      if total_odt > 0
        ped_prom = (sold / total_odt)
      else
        ped_prom = 0
      end
      
      # Here we calculate comissions and bonuses
      if date <= Time.mktime(2008, 10, 30, 23, 59, 59)
        # Old algorithm (for entries <= October 2008)
        if sold < quota
          bonus     = 0.00
          comission = 0.00
        else
          comission = (diff * (comission_rate / 100.00)).round
        end
      else
        # New algorithm!
        if sold < quota
          bonus = 0.00
        end
        
        # Comissions were calculated and buffered before
      end
      
      exec_data << OpenStruct.new({
        :user_id           => id,
        :name              => name,
        :sold              => sold,
        :quota             => quota,
        :diff              => diff,
        :bonus             => bonus,
        :billed            => billed,
        :facturated        => facturated,
        :comission         => comission,
        :comission_rate    => comission_rate,
        :productivity      => productivity,
        :total_odt         => total_odt,
        :ped_prom          => ped_prom,
        :sold_odts         => e[:sold_odts],
        :billed_odts       => e[:billed_odts],
        :facturated_odts   => e[:facturated_odts],
        :unbilled_odts     => e[:unbilled_odts],
        :unfacturated_odts => e[:unfacturated_odts]
      })
    end
    
    return exec_data
  end
  
  
  def self.new_exec_item(e, date)
  # Convenience method for calculation of Executive Quotas
    if e.cuota(date).nil?
      quota     = 0
      bonus     = 0
      comission = 0
    else
      quota     = e.cuota(date).cuota
      bonus     = e.cuota(date).bonificacion
      comission = e.cuota(date).comision
    end
    
    return {
      :user              => e,
      :sold              => 0,
      :billed            => 0,
      :facturated        => 0,
      :total_odt         => 0,
      :quota             => quota,
      :bonus             => bonus,
      :comission_rate    => comission,
      :comission         => 0,
      :sold_odts         => [],
      :billed_odts       => [],
      :facturated_odts   => [],
      :unbilled_odts     => [],
      :unfacturated_odts => []
    }
  end
  
  
  def self.insumos_percent
  # The percentage we use to trigger notifications for exceeded Insumos
  # in exports controller, insumos_cron
    return File.open(RAILS_ROOT + "/config/insumos_percent.txt").readlines.join.to_i
  end
  
  
  def self.set_insumos_percent(p)
    f = File.open(RAILS_ROOT + "/config/insumos_percent.txt", "w")
    f.puts p.strip
    f.close
    return true
  end
  
  
  def facturated_price_redefined?
    redef = self.op_fact_price_redef
    
    if redef.nil? || (redef.auth_exec? == true && redef.auth_fact? == true)
      return true
    else
      return false
    end
  end
  
  
  def promote_to_odt
    return true if self.con_orden_de_trabajo?
    
    self.orden_id                = Proyecto.get_new_order_id
    self.fecha_creacion_odt      = Time.now
    self.con_orden_de_trabajo    = true
    
    self.opportunity.date_closed = self.fecha_creacion_odt
    self.opportunity.save
    self.save
    
    return true
  end
  
  
  def has_notes?
    return self.con_nota_de_credito?
  end
  
  
  def self.update_variable_costs
    ps = Proyecto.find_by_sql "
      SELECT proyectos.*
        FROM guias_de_remisiones,
             proyectos
       WHERE guias_de_remisiones.proyecto_id=proyectos.id
         AND ultima_guia='1'
         AND proyectos.inmutable='0'
    "
    
    ps.each do |p|
      begin
        p.variable_cost
      rescue
      end
    end
    
    return true
  end
  
  
  def truput
    return (self.monto_de_venta_as_dollars - self.costo_variable).round2
  end
  
  
  def margen
    return 0.00 if self.monto_de_venta_as_dollars == 0.00
    return (self.truput / self.monto_de_venta_as_dollars).round2
  end
  
  
  def self.list_of_orders_to_validate
    return Proyecto.find_by_sql("
      SELECT *
        FROM proyectos
       WHERE estado_validacion='#{E_VALIDACION_POR_APROBAR}'
    ORDER BY id DESC")
  end
  
  
  def update_guia_data
    return true if self.inmutable?
    
    if CLOSED_ODTS[self.orden_id]
      fecha_cierre = fecha_recepcion = CLOSED_ODTS[self.orden_id]
    
    else
      gs = GuiaDeRemision.find_by_sql "
        SELECT *
          FROM guias_de_remisiones
         WHERE proyecto_id='#{self.id}'
           AND en_blanco='0'
           AND anulada='0'
           AND fecha_despacho IS NOT NULL
           "
      
      fecha_recepcion = nil
      fecha_cierre    = nil
      
      unless gs.empty?
        gs.each do |g|
          unless g.fecha_despacho.nil?
            if fecha_recepcion.nil?
              fecha_recepcion = g.fecha_despacho
            else
              fecha_recepcion = g.fecha_despacho if g.fecha_despacho > fecha_recepcion
            end
          end
        end
        
        if self.last_guia
          fecha_cierre = self.last_guia.fecha_emision
        end
      end
    end
    
    self.fecha_de_recepcion_del_cliente = fecha_recepcion
    self.fecha_cierre_odt               = fecha_cierre
    self.save
  
    return true
  end
  
  
  def has_related_order?
    return self.orden_relacionada.nil? == false
  end
  
  
  def related_order
    if self.orden_relacionada.nil?
      return nil
    else
      return Proyecto.find(self.orden_relacionada)
    end
  end
  
  
  def self.export_guias
    conditions = "proyectos.con_orden_de_trabajo='1' AND guia_exportada='0' AND inmutable='0'"
    ps = Proyecto.find :all, :conditions => conditions, :order => "proyectos.id"
  
    ps.each do |p|
      if g = p.last_guia
        f = File.open(BUDGET_EXPORT_PATH + "U" + p.orden_id.to_s.rjust(10, "0") + ".txt", "w")
        f.print p.orden_id.to_s.rjust(5, "0")
        f.print g.fecha_despacho.strftime("%d/%m/%Y")
        f.close
        
        p.guia_exportada = "1"
        p.save
      end
    end
  end
  
  
  def all_fechas_de_entrega_accepted?
    all_accepted = true
    
    self.fechas_de_entrega.each do |f|
      all_accepted = false unless f.accepted?
    end
    
    return all_accepted
  end
  
  
  def fechas_de_entrega_being_modified?
    mod = false
    
    self.fechas_de_entrega.each do |f|
      mod = true if f.awaiting_modification_approval?
    end
    
    return mod
  end
  
  
  def fechas_de_entrega_log
    return FechasDeEntregaLog.find_by_sql("SELECT * FROM fechas_de_entrega_log WHERE proyecto_id='#{self.id}' ORDER BY id")
  end
  
  
  def subtipo_nuevo_proyecto_mobiliario?
    return self.subtipo_nuevo_proyecto.to_i == SUBTIPO_NUEVO_PROYECTO_MOBILIARIO
  end
  
  
  def subtipo_nuevo_proyecto_arquitectura?
    return self.subtipo_nuevo_proyecto.to_i == SUBTIPO_NUEVO_PROYECTO_ARQUITECTURA
  end
  
  
  def update_fechas_de_entrega_status!
    if !self.area.nil? && self.area.en_operaciones?
      if self.all_fechas_de_entrega_accepted?
        self.area.estado_operaciones = E_OPERACIONES_TERMINADO
        self.area.salida_operaciones = Time.now
      elsif self.fechas_de_entrega_being_modified?
        self.area.estado_operaciones = E_OPERACIONES_EN_MODIFICACION
      else
        self.area.estado_operaciones = E_OPERACIONES_EN_PROCESO
      end
      
      self.area.save
    end
  end
  
  
  def quantity_available_for_guia
    return self.fechas_de_entrega.inject(0) { |sum, f| sum + f.quantity_available_for_guia }
  end
  
  
  def last_factura
    if self.has_facturas_or_boletas? && self.odt_cerrada?
      return self.of.last.factura
    else
      return false
    end
  end
  
  
  def igv
    if self.has_facturas_or_boletas?
      return self.of.first.igv
    else
      return get_igv_for(self.fecha_creacion_odt)
    end
  end
end

