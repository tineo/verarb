class CreateGrioProyectos < ActiveRecord::Migration
  def self.up
    create_table :grio_proyectos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :grio_proyectos
  end
end
