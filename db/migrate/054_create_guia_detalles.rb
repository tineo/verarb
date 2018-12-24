class CreateGuiaDetalles < ActiveRecord::Migration
  def self.up
    create_table :guia_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :guia_detalles
  end
end
