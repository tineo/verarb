class GuiaDeRemision < ActiveRecord::Base
  set_table_name "guias_de_remisiones"
  belongs_to :factura
  belongs_to :proyecto
  has_many :detalles, { :class_name => "GuiaDetalle", :order => "id" }
  belongs_to :account
  before_create :check_number
  after_save :update_odt
  
  def self.get_next_number(empresa, serie)
    a = GuiaDeRemision.find_by_sql "SELECT MAX(numero) AS numero
                                  FROM guias_de_remisiones
                                 WHERE empresa='#{empresa}'
                                   AND serie='#{serie}'"
								   
    if a.first.numero.nil?
      n = 0
    else
      n = a.first.numero
    end
    
    return n + 1
  end
 
  
  def self.get_list_of_back_numbers_for(empresa, serie)
    if serie == "1"
      max = self.get_next_number(empresa, serie)
    else
      max = 2000
    end
    
    numbers = self.find_by_sql "SELECT numero FROM guias_de_remisiones WHERE empresa='#{empresa}' AND serie='#{serie}' AND numero <= #{max}"
    
    list = numbers.inject([]) do |m, n|
      m << n.numero
    end
    
    new_list = []
    
    1.upto(max) do |n|
      new_list << n unless list.include? n
    end
    
    new_list.reverse!
    
    return new_list
  end
  
  
  def self.format_number(empresa, series, number)
    return EMPRESA_VENDEDORA_SHORT[empresa] + "-" + series.to_s.rjust(3, "0") + "-" + number.to_s.rjust(6, "0")
  end
  
  
  def formatted_number
    return GuiaDeRemision.format_number(self.empresa, self.serie, self.numero)
  end
  
  
  def all_descriptions
    descripcion = ""
    
    self.detalles.each do |d|
      descripcion += "<li> " + d.descripcion + "\n"
    end
    
    return descripcion
  end
  
  
  def all_quantities
    return self.detalles.inject(0) { |sum, d| sum + d.cantidad }
  end
  
  
  def belongs_to?(factura)
    fg = FacturaGuia.find_by_factura_id_and_guia_de_remision_id factura.id, self.id
    return fg != nil
  end
  
  
  def facturada?
    f = FacturaGuia.find_by_sql "SELECT COUNT(*) AS total
                                 FROM facturas_guias,
                                      facturas
                                WHERE facturas_guias.factura_id=facturas.id
                                  AND facturas.anulada='0'
                                  AND facturas_guias.guia_de_remision_id='#{self.id}'"
    
    return f[0].total.to_i > 0
  end
  
  
  def check_number
  # Verifies if the number we want to use to create this Guía is already used
    g = GuiaDeRemision.find_by_sql "SELECT * FROM guias_de_remisiones WHERE empresa='#{self.empresa}' AND serie='#{self.serie}' AND numero='#{self.numero}'"
    
    unless g.empty?
      raise "GUIA_NUMBER_ALREADY_EXISTS"
    end
    
    return true
  end
  
  
  def blank!
    self.proyecto_id         = nil
    self.fecha_emision       = nil
    self.fecha_despacho      = nil
    self.fecha_retorno       = nil
    self.responsable         = nil
    self.lugar_de_entrega    = nil
    self.localidad           = nil
    self.observaciones       = nil
    self.anulada             = nil
    self.account_id          = nil
    self.ultima_guia         = nil
    self.en_blanco           = true
    self.save
    
    self.detalles.each do |d|
       d.destroy
    end
    
    return true
  end
  
  
  def self.find_usable_for_new(serie, empresa)
  # Returns an array of Guias which are usable because they are blank
    sql = "SELECT *
             FROM guias_de_remisiones
            WHERE en_blanco='1'
              AND serie='#{serie}'
              AND empresa='#{empresa}'
         ORDER BY serie, numero DESC"
    
    return GuiaDeRemision.find_by_sql(sql)
  end
  
  
  def update_odt
    self.proyecto.update_guia_data unless self.en_blanco? || self.proyecto.nil?
    return true
  end
  
  
  def set_to_odt(oid)
    p = Proyecto.find_odt(oid)
    
    self.proyecto_id = p.id
    self.save
    
    return true
  end
end

