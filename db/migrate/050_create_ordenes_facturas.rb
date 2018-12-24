class CreateOrdenesFacturas < ActiveRecord::Migration
  def self.up
    create_table :ordenes_facturas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :ordenes_facturas
  end
end
