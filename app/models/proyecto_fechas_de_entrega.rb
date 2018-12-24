class ProyectoFechasDeEntrega < ActiveRecord::Base
# It's a log of Fechas de Entrega
  set_table_name "proyecto_fechas_de_entrega"
  belongs_to :proyecto
  belongs_to :user
end

