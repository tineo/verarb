class CreateEmpresaUsers < ActiveRecord::Migration
  def self.up
    create_table :empresa_users do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :empresa_users
  end
end
