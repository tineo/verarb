class CreateOTCabeceras < ActiveRecord::Migration
  def self.up
    create_table :ot_cabeceras do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :ot_cabeceras
  end
end
