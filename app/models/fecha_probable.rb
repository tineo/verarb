class FechaProbable < ActiveRecord::Base
  set_table_name "facturas_fechas_probables"
  belongs_to :factura
  after_save :update_factura
  
  def update_factura
    f = Factura.find self.factura_id
    f.fecha_probable = self.fecha
    f.save
  end
end
