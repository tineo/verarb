class CreatePermisos < ActiveRecord::Migration
  def self.up
    create_table :permisos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :permisos
  end
end
