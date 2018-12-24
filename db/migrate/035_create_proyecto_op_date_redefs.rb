class CreateProyectoOPDateRedefs < ActiveRecord::Migration
  def self.up
    create_table :proyecto_op_date_redefs do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :proyecto_op_date_redefs
  end
end
