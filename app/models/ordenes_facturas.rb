class OrdenesFacturas < ActiveRecord::Base
  set_table_name "ordenes_facturas"
  belongs_to :proyecto
  belongs_to :factura
  before_save :calculate_amount
  
  def calculate_amount
    if self.ignorar_descuento?
      self.monto_activo = self.monto_odt
    else
      self.monto_activo = self.monto_odt - self.monto_credito
    end
  end
  
  
  def monto_odt_with_igv
    return self.monto_odt * self.igv
  end
  
  
  def monto_activo_with_igv
    return self.monto_activo * self.igv
  end
  
  
  def monto_activo_in_factura_currency
    if self.factura.moneda != self.moneda_odt
      if self.moneda_odt == 'S'
        return self.monto_activo_as_dollars
      else
        return self.monto_activo_as_soles
      end
    else
      return self.monto_activo
    end
  end
 
  
  def monto_activo_as_dollars(igv = nil)
    if self.moneda_odt == 'S'
      m = ((self.monto_activo / self.factura.tipo_de_cambio) * 100).round / 100.0
    else
      m = self.monto_activo
    end
    
    if igv.nil?
      return m
    else
      return m * self.igv
    end
  end
  
  
  def monto_activo_as_soles(igv = nil)
    if self.moneda_odt == 'D'
      m = ((self.monto_activo * self.factura.tipo_de_cambio) * 100).round / 100.0
    else
      m = self.monto_activo
    end
    
    if igv.nil?
      return m
    else
      return m * self.igv
    end
  end
  
  
  def monto_odt_in_factura_currency
    if self.factura.moneda != self.moneda_odt
      if self.moneda_odt == 'S'
        return self.monto_odt_as_dollars
      else
        return self.monto_odt_as_soles
      end
    else
      return self.monto_odt
    end
  end
 
  
  def monto_odt_as_dollars(igv = nil)
    if self.moneda_odt == 'S'
      m = ((self.monto_odt / self.factura.tipo_de_cambio) * 100).round / 100.0
    else
      m = self.monto_odt
    end
    
    if igv.nil?
      return m
    else
      return m * self.igv
    end
  end
  
  
  def monto_odt_as_soles(igv = nil)
    if self.moneda_odt == 'D'
      m = ((self.monto_odt * self.factura.tipo_de_cambio) * 100).round / 100.0
    else
      m = self.monto_odt
    end
    
    if igv.nil?
      return m
    else
      return m * self.igv
    end
  end
  
  
  def igv
    return get_igv_for(self.factura.fecha_emision)
  end
  
end
