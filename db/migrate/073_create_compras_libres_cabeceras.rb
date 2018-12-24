class CreateComprasLibresCabeceras < ActiveRecord::Migration
  def self.up
    create_table :compras_libres_cabeceras do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :compras_libres_cabeceras
  end
end
