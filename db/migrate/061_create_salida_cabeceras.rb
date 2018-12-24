class CreateSalidaCabeceras < ActiveRecord::Migration
  def self.up
    create_table :salida_cabeceras do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :salida_cabeceras
  end
end
