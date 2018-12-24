class GuiaDetalle < ActiveRecord::Base
  set_table_name "guia_detalles"
  
  belongs_to :guia, { :class_name => "GuiaDeRemision" }
  
  
  def fecha_de_entrega
    return FechasDeEntrega.find(self.fechas_de_entrega_id)
  end
  
  
  def quantity_available_from_plant_when_editing
    if self.fechas_de_entrega_id.nil?
      return self.cantidad * 100
    else
      return self.fecha_de_entrega.quantity_available_for_guia + self.cantidad
    end
  end
end
