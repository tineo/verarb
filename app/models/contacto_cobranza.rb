class ContactoCobranza < ActiveRecord::Base
  set_table_name "contactos_cobranzas"
  belongs_to :account
end
