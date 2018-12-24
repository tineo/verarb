class ProyectoFactPriceRedef < ActiveRecord::Base
  set_table_name "proyecto_fact_price_redef"
  belongs_to :proyecto
end
