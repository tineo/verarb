class Notificacion < ActiveRecord::Base
  set_table_name "notificaciones"
  belongs_to :proyecto
  
  def self.new_from_mail(uid, tipo, m)
    n = Notificacion.new
    n.descripcion = m.body
    
    return n
  end
end
