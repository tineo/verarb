class ProyectoOPDateRedef < ActiveRecord::Base
  set_table_name "proyecto_op_date_redef"
  belongs_to :proyecto
end
