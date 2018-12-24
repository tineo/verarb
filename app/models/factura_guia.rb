class FacturaGuia < ActiveRecord::Base
  set_table_name "facturas_guias"
  belongs_to :factura
  belongs_to :guia, { :class_name => "GuiaDeRemision" }
  
  def self.delete_all_for(factura)
    fid = factura.id
    
    FacturaGuia.destroy_all "factura_id='#{fid}'" 
  end
end
