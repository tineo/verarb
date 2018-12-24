class CreateGroupMembers < ActiveRecord::Migration
  def self.up
    create_table :group_members do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :group_members
  end
end
