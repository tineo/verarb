class CreateAreas < ActiveRecord::Migration
  def self.up
    create_table :areas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :areas
  end
end
