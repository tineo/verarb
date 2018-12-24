class UsuariosRoles < ActiveRecord::Base
  set_table_name "vera_usuarios_roles"
  belongs_to :rol
end
