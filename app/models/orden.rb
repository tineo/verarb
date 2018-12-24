class Orden < ActiveRecord::Base
  belongs_to :proyecto
  has_many :puntos_de_entrega, :order => "id"
  
  def self.list_all
    Orden.find :all, :order => "id DESC"
  end
  
  
  def monto_de_venta
    self.proyecto.opportunity.amount
  end
end
