class Factura < ActiveRecord::Base
  has_many :of, { :class_name => "OrdenesFacturas", :order => "ordenes_facturas.id" }
  has_many :details, { :class_name => "FacturaDetalle", :order => "factura_detalles.id" }
  has_many :fg, { :class_name => "FacturaGuia" }
  belongs_to :account
  has_many :fechas_probables, { :class_name => "FechaProbable", :order => "created_on DESC" }
  has_many :notes, { :class_name => "NotaDeCredito", :conditions => "anulada='0'", :order => "created_on" }
  
  before_save :update_monto
  after_save  :update_odts
  
  def status
    if self.anulada?
      return "Anulada"
    elsif self.en_blanco?
      return "En Blanco"
    elsif !self.completa?
      return "Incompleta"
    elsif self.has_notes?
      return "Descontada"
    elsif self.cobrada?
      return "Cobrada"
    else
      return "Emitida"
    end
  end
  
  
  def update_monto
  # This automagically updates the Factura's monto
    # Sum up Soles
    s = (Factura.find_by_sql "SELECT SUM(monto_odt) AS monto FROM facturas, ordenes_facturas WHERE ordenes_facturas.factura_id=facturas.id AND facturas.anulada='0' AND facturas.id='#{self.id}' AND moneda_odt='S'")[0].monto
    s = 0.00 if s.nil?
    
    # Sum up Dollars
    d = (Factura.find_by_sql "SELECT SUM(monto_odt) AS monto FROM facturas, ordenes_facturas WHERE ordenes_facturas.factura_id=facturas.id AND facturas.anulada='0' AND facturas.id='#{self.id}' AND moneda_odt='D'")[0].monto
    d = 0.00 if d.nil?
    
    # Now, the Credit Notes
    monto_credito = 0.00
    
    # Sum up
    m = (NotaDeCredito.find_by_sql "SELECT SUM(monto) AS monto FROM notas_de_creditos WHERE notas_de_creditos.anulada='0' AND factura_id='#{self.id}'")[0].monto
    if m.nil?
      monto_credito = 0.00
    else
      monto_credito = m
    end
    
    # Convert!
    unless self.tipo_de_cambio.nil?
      if self.moneda == 'S'
        d = ((d * self.tipo_de_cambio) * 100).round / 100.0
      else
        s = ((s / self.tipo_de_cambio) * 100).round / 100.0
      end
    end
    
    self.monto         = s + d
    self.monto_credito = monto_credito
    self.monto_activo  = self.monto - self.monto_credito
    
    return true
  end
  
  
  def update_odts
  # After saving this Factura, we update the ODTs that belong to it
    return true if @dont_update_odts
    
    self.of.each do |o|
      o.proyecto.save unless o.proyecto.inmutable?
    end
    
    return true
  end
  
  
  def mark_as_last_factura!
    @dont_update_odts = true
    self.ultima_factura = true
    self.save
    @dont_update_odts = false
  end
  
  
  def unmark_as_last_factura!
    @dont_update_odts = true
    self.ultima_factura = false
    self.save
    @dont_update_odts = false
  end
  
  
  def self.find_usable_for_new(type, empresa)
  # Returns an array of Factura IDs which are usable because they are
  # a) Blank, left for use later
  # b) Marked as incomplete. Belongs to many Orders, but hasn't still been
  #    assigned to all of its Orders in Vera.
    sql = "SELECT *
             FROM facturas
            WHERE (completa='0' OR en_blanco='1')
              AND tipo='#{type}'
              AND empresa='#{empresa}'
              AND anulada='0'"
    
    fs = Factura.find_by_sql(sql)
    
    fs.map! { |i| i.numero.to_i }
    
    return fs.sort.reverse
  end
  
  
  def self.exists_for(fid, pid, type)
  # Checks if a certain Factura was already created for an Order
    x = OrdenesFacturas.find_by_sql "SELECT * FROM ordenes_facturas, facturas WHERE facturas.id=ordenes_facturas.factura_id AND facturas.numero='#{fid}' AND tipo='#{type}' AND ordenes_facturas.proyecto_id='#{pid}' AND facturas.anulada='0'"
    
    return !x.empty?
  end
  
  
  def proposed_charge_date
    # Calculates the date to charge this Factura according to the
    # received date + dias de plazo
    return nil if self.fecha_recepcion.nil?
    return self.fecha_recepcion + (self.dias_plazo * 60 * 60 * 24)
  end
  
  
  def monto_as_soles
    return 0.0 if self.monto.nil?
    
    if self.moneda == "S"
      return self.monto
    else
      return (self.monto * self.tipo_de_cambio).round2
    end
  end
  
  
  def monto_as_dollars
    return 0.0 if self.monto.nil?
    return 0.0 if self.tipo_de_cambio.nil?
    
    if self.moneda == "D"
      return self.monto
    else
      return (self.monto / self.tipo_de_cambio).round2
    end
  end
  
  
  def monto_activo_as_soles
    return 0.0 if self.monto_activo.nil?
    
    if self.moneda == "S"
      return self.monto_activo
    else
      return (self.monto_activo * self.tipo_de_cambio).round2
    end
  end
  
  
  def monto_activo_as_dollars
    return 0.0 if self.monto_activo.nil?
    
    if self.moneda == "D"
      return self.monto_activo
    else
      return (self.monto_activo / self.tipo_de_cambio).round2
    end
  end
  
  
  def razon_social
    if self.account_id.nil? || self.account_id.empty?
      super
    else
      return self.account.name
    end
  end
  
  
  def ruc
    if self.account_id.nil? || self.account_id.empty?
      super
    else
      return self.account.ruc
    end
  end
  
  
  def dias_plazo
    # Find out the longest dia de plazo in all projects
    plazo = self.of.inject(0) do |m, o|
      d = o.proyecto.dias_plazo
      if d.nil?
        m
      else
        m > d ? m : d
      end
    end
    
    return plazo
  end
  
  
  def formatted_factura_number
    return "" if self.empresa.nil?
    s = self.numero.to_s.rjust(9, "0")
    return EMPRESA_VENDEDORA_SHORT[self.empresa] + "-" + s[0..2] + "-" + s[3..-1]
  end
  
  
  def current_fecha_probable
    self.fechas_probables.first
  end
  
  
  def blank!
    self.anulada                = false
    self.en_blanco              = true
    self.status                 = 0
    self.numero_orden_de_compra = nil
    self.fecha_emision          = nil
    self.fecha_recepcion        = nil
    self.quien_lo_dejo          = nil
    self.monto                  = nil
    self.moneda                 = nil
    self.tipo_de_cambio         = nil
    self.comentarios            = nil
    self.completa               = 0
    self.canje                  = 0
    self.razon_social           = nil
    self.ruc                    = nil
    self.account_id             = nil
    self.cobrada                = nil
    self.confirmada             = nil
    self.confirmed_on           = nil
    self.modalidad_pago         = nil
    self.fecha_probable         = nil
    self.cargo_cobranza         = 0
    self.fecha_cargo_cobranza   = nil
    self.con_nota_de_credito    = 0
    self.save
    
    # Destroy all its details
    self.details.each do |d|
      d.destroy
    end
    
    # We grab a list of all of the related Projects to this Factura
    # and destroy each of the OrdenesFacturas related to this one
    projects = []
    
    self.of.each do |o|
      projects << o.proyecto
      o.destroy
    end
    
    # Now, recalculate the Projects
    projects.each do |p|
      p.update_adelanto_status
      p.save
    end
    
    return true
  end
  
  
  def self.list_of_emitted_and_unconfirmed(companies_sql_list, aid = nil, type = nil)
    if aid == nil
      conditions = ""
    elsif type == :account
      conditions = "AND account_id='#{aid}'"
    else
      conditions = "AND ruc='#{aid}'"
    end
    
    list = Factura.find_by_sql "SELECT * FROM facturas WHERE DATE_SUB(CURDATE(), INTERVAL 7 DAY) >= fecha_emision AND cargo_cobranza='1' AND confirmada='0' AND cobrada='0' AND anulada='0' AND completa='1' #{conditions} AND en_blanco='0' AND empresa IN #{companies_sql_list}"
    
    list = list.sort_by { |f| f.razon_social }
    
    return list
  end
  
  
  def self.close_to_bill_date(companies_sql_list, aid = nil, type = nil)
    if aid == nil
      conditions = ""
    elsif type == :account
      conditions = "AND account_id='#{aid}'"
    else
      conditions = "AND ruc='#{aid}'"
    end
    
    list = Factura.find_by_sql "
      SELECT *
        FROM facturas
       WHERE DATE_ADD(CURDATE(), INTERVAL 7 DAY) >= fecha_probable
         AND cargo_cobranza='1'
         AND cobrada='0'
         AND fecha_probable IS NOT NULL
         AND anulada='0'
         AND completa='1'
         AND en_blanco='0'
         AND empresa IN #{companies_sql_list}
         #{conditions}
         ORDER BY fecha_probable"
    
    return list
  end
  
  
  def self.to_be_delivered(companies_sql_list)
    return Factura.find_by_sql("
      SELECT *
        FROM facturas
       WHERE fecha_recepcion IS NULL
         AND cargo_cobranza='1'
         AND en_blanco='0'
         AND completa='1'
         AND anulada='0'
         AND empresa IN #{companies_sql_list}
    ORDER BY fecha_emision")
  end
  
  
  def self.to_be_billed(companies_sql_list)
    return Factura.find_by_sql("
      SELECT *
        FROM facturas
       WHERE fecha_probable IS NOT NULL
         AND fecha_probable <= NOW()
         AND cargo_cobranza='1'
         AND en_blanco='0'
         AND anulada='0'
         AND cobrada='0'
         AND empresa IN #{companies_sql_list}
    ORDER BY fecha_emision")
  end
  
  
  def has_this_project?(pid)
    return (self.of.select { |of| of.proyecto.id == pid }).empty? == false
  end
  
  
  def can_be_added_this_project?(project)
  # Returns true if the Project object is valid to be added to this Factura
    return false if self.completa?
    return false if self.anulada?
    return false if self.cobrada?
    return false if self.has_this_project?(project.id)
    
    return true
  end
  
  
  def self.unloaded_invoices(companies_sql_list)
  # List of Facturas not received by Cobranza
    return Factura.find_by_sql("
      SELECT *
        FROM facturas
       WHERE empresa IN #{companies_sql_list}
         AND cargo_cobranza='0'
    ORDER BY empresa,
             numero,
             tipo
    ")
  end
  
  
  def loadable?
    return true if self.anulada?
    return false if self.en_blanco?
    return false if !self.completa?
    return true
  end
  
  
  def list_of_odts
    odts = []
    
    self.of.each do |o|
      odts << o.proyecto.orden_id
    end
    
    return odts.uniq.sort
  end
  
  
  def self.get_flow_for_week(dstart, dend)
  # Calculates the Billing Flow for the period given as start and end dates
    
    facturas = Factura.find_by_sql("SELECT * FROM facturas WHERE fecha_probable BETWEEN '#{dstart.strftime("%Y-%m-%d 00:00:00")}' AND '#{dend.strftime("%Y-%m-%d 12:59:59")}'")
    
    results = []
    
    facturas.each do |f|
      item = OpenStruct.new({
        :factura_number => f.formatted_factura_number,
        :odts           => f.list_of_odts,
        :cliente        => f.razon_social,
        :femision       => f.fecha_emision
        
      })
      
      results << item
    end
    
    return results
  end
  
  
  def update_details(details, project)
  # Updates the details coming from a Fionna form. For use when creating
  # a Factura (Previously, when editing it too -- hence this method. We
  # were trying to do DRY, but things changed. If you have the time, move
  # this code to the creation of a Factura.
    
    if self.con_una_sola_descripcion?
      FacturaDetalle.destroy_all "factura_id='#{self.id}'"
    end
    
    details.each do |d|
      fd = FacturaDetalle.new({
        :factura_id     => self.id,
        :proyecto_id    => project.id,
        :descripcion    => d.descripcion,
        :cantidad       => d.cantidad,
        :valor_unitario => d.valor_unitario
      })
      fd.save
    end
  end
  
  
  def direccion_fiscal
    return self.factura_direccion_fiscal || ""
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
  
  
  def parse_details_for_pdf
    descripciones = []
    cantidades    = []
    valores       = []
    ventas        = []
    odt           = nil
    
    self.details.each do |d|
      if self.con_una_sola_descripcion?
        text = ""
      else
        if odt != d.proyecto.orden_id
          odt  = d.proyecto.orden_id
          text = "--- ODT #{odt} ---\n"
        else
          text = ""
        end
      end
      
      td = text + d.descripcion.factura_format(78, 19)
      
      descripciones << td
      cantidades    << d.cantidad.to_s.factura_format(18, 1).rjust(18, " ")
      valores       << format_price(d.valor_unitario).factura_format(17, 1).rjust(17, " ")
      ventas        << format_price(d.valor_de_venta).factura_format(17, 1).rjust(17, " ")
      
      # How many empty lines should we leave for the other fields?
      c = td.split("\n").size
      
      c.times do
        cantidades << ""
        valores    << ""
        ventas     << ""
      end
    end
    
    descripciones = descripciones.join("\n\n").factura_format(78, 19)
    cantidades    = cantidades.join("\n")
    valores       = valores.join("\n")
    ventas        = ventas.join("\n")
  end
  
  
  def has_notes?
    return self.notes.empty? == false
  end
end

