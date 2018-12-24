class Servicio < ActiveRecord::Base
  belongs_to :categoria
  
  def self.of_category(cid)
    Servicio.find_by_sql ["SELECT * FROM servicios WHERE categoria_id=? AND activo=1 ORDER BY nombre", cid]
  end
end
