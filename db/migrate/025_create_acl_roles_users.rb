class CreateAclRolesUsers < ActiveRecord::Migration
  def self.up
    create_table :acl_roles_users do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :acl_roles_users
  end
end
