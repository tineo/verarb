class CreateUserVoidLists < ActiveRecord::Migration
  def self.up
    create_table :user_void_lists do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :user_void_lists
  end
end
