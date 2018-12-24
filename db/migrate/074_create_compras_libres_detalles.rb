class CreateComprasLibresDetalles < ActiveRecord::Migration
  def self.up
    create_table :compras_libres_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :compras_libres_detalles
  end
end
