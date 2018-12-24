class Categoria < ActiveRecord::Base
  has_many :atributos
  
  def self.of_products
    Categoria.find :all, :conditions => "tipo='P' AND activo='1'", :order => "nombre"
  end
  
  
  def self.of_services
    Categoria.find :all, :conditions => "tipo='S' AND activo='1'", :order => "nombre"
  end
end
