class Producto < ActiveRecord::Base
  has_many :atributos, :order => "orden"
  belongs_to :categoria
  
  def self.of_category(cid)
    Producto.find_by_sql ["SELECT * FROM productos WHERE categoria_id=? AND activo=1 ORDER BY nombre", cid]
  end
  
  
  def get_files
    return FileList.new(self.path)
  end
  
  
  def path
    PRODUCTS_PATH + self.id.to_s + "/"
  end
  
  
  def get_image
  # Returns the filename of its image
    image = ''
    
    self.get_files.each do |f|
      if [".jpg", ".JPG", ".gif", ".GIF", ".png", ".PNG"].include? f.extension
        image = f
      end
    end
    
    return image
  end
end
