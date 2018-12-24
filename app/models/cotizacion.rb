class Cotizacion < ActiveRecord::Base
  belongs_to :proyecto
  has_many :cotizacion_detalles, :order => "id"
  
  def self.mark(id)
    Cotizacion.find(:all).each do |c|
      if c.id == id
        c.marked = "1"
      else
        c.marked = "0"
      end
      
      c.save
    end
  end
  
  def details
    self.cotizacion_detalles
  end
end
