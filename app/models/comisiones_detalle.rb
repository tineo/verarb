class ComisionesDetalle < ActiveRecord::Base
  belongs_to :comisiones_cabecera, :foreign_key => "comisiones_cabecera_id"
  belongs_to :project, :class_name => "Proyecto"
end
