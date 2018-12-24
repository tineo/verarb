class Detalle < ActiveRecord::Base
  belongs_to :proyecto
  belongs_to :producto
  belongs_to :servicio
  has_many :atributos_detalle,
           :order => "orden, nombre"
  
  def self.get_all_approved_of_project(pid)
    Detalle.find_all_by_proyecto_id_and_aprobado(pid, "1")
  end
  
  
  def get_project_files
    return FileList.new(self.path)
  end
  
  
  def path
    PROJECTS_PATH + self.proyecto_id.to_s + "/" + self.id.to_s + "/"
  end
  
  
  def get_image
  # Returns the filename of the project image if it's a Product
    image = ''
    
    if self.tipo == "P"
      self.get_project_files.each do |f|
        if [".jpg", ".JPG", ".gif", ".GIF", ".png", ".PNG"].include? f.extension
          image = f.filename
        end
      end
    end
    
    return image
  end
  
end
