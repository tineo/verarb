class Mensaje < ActiveRecord::Base
  belongs_to :proyecto
  belongs_to :user
  
  def self.diseno(pid)
    Mensaje.find_all_by_proyecto_id_and_area_id pid, A_DISENO, :order => "fecha DESC"
  end
  
  
  def self.diseno_desarrollo(pid)
    Mensaje.find_all_by_proyecto_id_and_area_id pid, A_DISENO_DESARROLLO, :order => "fecha DESC"
  end
  
  
  def self.planeamiento(pid)
    Mensaje.find_all_by_proyecto_id_and_area_id pid, A_PLANEAMIENTO, :order => "fecha DESC"
  end
  
  
  def self.costos(pid)
    Mensaje.find_all_by_proyecto_id_and_area_id pid, A_COSTOS, :order => "fecha DESC"
  end
  
  
  def self.innovaciones(pid)
    Mensaje.find_all_by_proyecto_id_and_area_id pid, A_INNOVACIONES, :order => "fecha DESC"
  end
  
  
  def self.instalaciones(pid)
    Mensaje.find_all_by_proyecto_id_and_area_id pid, A_INSTALACIONES, :order => "fecha DESC"
  end
  
  
  def self.operaciones(pid)
    Mensaje.find_all_by_proyecto_id_and_area_id pid, A_OPERACIONES, :order => "fecha DESC"
  end
end
