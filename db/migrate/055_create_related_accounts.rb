class CreateRelatedAccounts < ActiveRecord::Migration
  def self.up
    create_table :related_accounts do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :related_accounts
  end
end
