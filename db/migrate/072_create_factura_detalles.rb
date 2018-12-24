class CreateFacturaDetalles < ActiveRecord::Migration
  def self.up
    create_table :factura_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :factura_detalles
  end
end
