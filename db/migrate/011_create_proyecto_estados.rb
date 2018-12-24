class CreateProyectoEstados < ActiveRecord::Migration
  def self.up
    create_table :proyecto_estados do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :proyecto_estados
  end
end
