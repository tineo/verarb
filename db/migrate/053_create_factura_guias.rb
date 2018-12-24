class CreateFacturaGuias < ActiveRecord::Migration
  def self.up
    create_table :factura_guias do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :factura_guias
  end
end
