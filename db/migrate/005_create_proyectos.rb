class CreateProyectos < ActiveRecord::Migration
  def self.up
    create_table :proyectos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :proyectos
  end
end
