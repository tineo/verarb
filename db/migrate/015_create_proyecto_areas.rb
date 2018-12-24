class CreateProyectoAreas < ActiveRecord::Migration
  def self.up
    create_table :proyecto_areas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :proyecto_areas
  end
end
