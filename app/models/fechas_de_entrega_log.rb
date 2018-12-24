class FechasDeEntregaLog < ActiveRecord::Base
  set_table_name "fechas_de_entrega_log"
  belongs_to :user
end
