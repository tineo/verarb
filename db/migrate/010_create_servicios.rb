class CreateServicios < ActiveRecord::Migration
  def self.up
    create_table :servicios do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :servicios
  end
end
