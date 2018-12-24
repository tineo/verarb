class CreateRequerimientos < ActiveRecord::Migration
  def self.up
    create_table :requerimientos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :requerimientos
  end
end
