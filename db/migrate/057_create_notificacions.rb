class CreateNotificacions < ActiveRecord::Migration
  def self.up
    create_table :notificacions do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :notificacions
  end
end
