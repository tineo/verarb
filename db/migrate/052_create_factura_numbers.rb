class CreateFacturaNumbers < ActiveRecord::Migration
  def self.up
    create_table :factura_numbers do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :factura_numbers
  end
end
