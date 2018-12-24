class FacturaDetalle < ActiveRecord::Base
  belongs_to :factura
  belongs_to :proyecto
  set_table_name "factura_detalles"
  
  
  def valor_de_venta
    return self.cantidad * self.valor_unitario
  end
end
