class EmpresaUser < ActiveRecord::Base
  set_table_name "empresas_users"
  belongs_to :user
end
