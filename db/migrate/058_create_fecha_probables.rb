class CreateFechaProbables < ActiveRecord::Migration
  def self.up
    create_table :fecha_probables do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :fecha_probables
  end
end
