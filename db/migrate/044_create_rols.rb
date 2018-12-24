class CreateRols < ActiveRecord::Migration
  def self.up
    create_table :rols do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :rols
  end
end
