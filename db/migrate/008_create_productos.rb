class CreateProductos < ActiveRecord::Migration
  def self.up
    create_table :productos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :productos
  end
end
