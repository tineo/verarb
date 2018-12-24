class CreateServicioItems < ActiveRecord::Migration
  def self.up
    create_table :servicio_items do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :servicio_items
  end
end
