class CreateAtributosDetalles < ActiveRecord::Migration
  def self.up
    create_table :atributos_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :atributos_detalles
  end
end
