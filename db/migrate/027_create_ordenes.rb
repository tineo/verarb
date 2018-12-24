class CreateOrdenes < ActiveRecord::Migration
  def self.up
    create_table :ordenes do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :ordenes
  end
end
