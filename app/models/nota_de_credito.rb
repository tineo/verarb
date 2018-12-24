class NotaDeCredito < ActiveRecord::Base
  set_table_name "notas_de_creditos"
  has_many :details, { :class_name => "NotaDetalle", :order => "nota_detalles.id" }
  belongs_to :factura
  
  def status
    if self.anulada?
      return "Anulada"
    elsif self.en_blanco?
      return "En Blanco"
    elsif self.cobrada?
      return "Cobrada"
    else
      return "Emitida"
    end
  end
  
  
  def self.find_usable_for_new(type, empresa)
  # Returns an array of Notes IDs which are usable because they are
  # blank, left for use later
    sql = "SELECT *
             FROM notas_de_creditos
            WHERE en_blanco='1'
              AND tipo='#{type}'
              AND empresa='#{empresa}'
              AND anulada='0'
         ORDER BY numero DESC"
    
    fs = NotaDeCredito.find_by_sql(sql)
    
    fs.map! { |i| i.numero.to_i }
    
    return fs.sort.reverse
  end
  
  
  def blank?
    return self.en_blanco?
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
    self.save
    
    # Destroy all its details
    self.details.each do |d|
      d.destroy
    end
    
    # FIXME, missing factura things here
    # 
    return true
  end
  
  
  def formatted_number
    return "" if self.empresa.nil?
    
    s = self.numero.to_s.rjust(9, "0")
    return EMPRESA_VENDEDORA_SHORT[self.empresa] + "-" + s[0..2] + "-" + s[3..-1]
  end
  
  
  def monto_as_soles
    return 0.0 if self.monto.nil?
    
    if self.moneda == "S"
      return self.monto
    else
      return (self.monto * self.factura.tipo_de_cambio).round2
    end
  end
  
  
  def monto_as_dollars
    return 0.0 if self.monto.nil?
    
    if self.moneda == "D"
      return self.monto
    else
      return (self.monto / self.factura.tipo_de_cambio).round2
    end
  end
  
  
end
