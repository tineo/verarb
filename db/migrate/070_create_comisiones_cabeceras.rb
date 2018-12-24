class CreateComisionesCabeceras < ActiveRecord::Migration
  def self.up
    create_table :comisiones_cabeceras do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :comisiones_cabeceras
  end
end
