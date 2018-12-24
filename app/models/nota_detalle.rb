class NotaDetalle < ActiveRecord::Base
  belongs_to :nota_de_credito
  set_table_name "nota_detalles"
  
  def valor_de_venta
    return self.cantidad * self.valor_unitario
  end
end
