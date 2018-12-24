class CreateNotificationLists < ActiveRecord::Migration
  def self.up
    create_table :notification_lists do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :notification_lists
  end
end
