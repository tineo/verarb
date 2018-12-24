class CreateInsumoProveedors < ActiveRecord::Migration
  def self.up
    create_table :insumo_proveedors do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :insumo_proveedors
  end
end
