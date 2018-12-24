class TerminadosEnPlanta < ActiveRecord::Base
  set_table_name "terminados_en_planta"
  belongs_to :fechas_de_entrega
  
  
  def self.reset(date)
    TerminadosEnPlanta.destroy_all ["fechas_de_entrega_id=?", date.id]
    return true
  end
end
