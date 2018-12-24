class CreateAccountExtras < ActiveRecord::Migration
  def self.up
    create_table :account_extras do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :account_extras
  end
end
