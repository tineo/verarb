class CreateFacturas < ActiveRecord::Migration
  def self.up
    create_table :facturas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :facturas
  end
end
