class GrioProyecto < ActiveRecord::Base
  belongs_to :grio, {
               :class_name  => "Proyecto",
               :foreign_key => "grio_id"
             }
end
