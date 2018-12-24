class CreateInsumoItems < ActiveRecord::Migration
  def self.up
    create_table :insumo_items do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :insumo_items
  end
end
