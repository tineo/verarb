class CreateComisionesDetalles < ActiveRecord::Migration
  def self.up
    create_table :comisiones_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :comisiones_detalles
  end
end
