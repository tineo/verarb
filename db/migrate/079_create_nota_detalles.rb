class CreateNotaDetalles < ActiveRecord::Migration
  def self.up
    create_table :nota_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :nota_detalles
  end
end
