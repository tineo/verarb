class CreateOrdenid < ActiveRecord::Migration
  def self.up
    create_table :orden_ids do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :orden_ids
  end
end
