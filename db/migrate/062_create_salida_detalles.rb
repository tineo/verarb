class CreateSalidaDetalles < ActiveRecord::Migration
  def self.up
    create_table :salida_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :salida_detalles
  end
end
