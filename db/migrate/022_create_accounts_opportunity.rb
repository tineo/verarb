class CreateAccountsOpportunity < ActiveRecord::Migration
  def self.up
    create_table :accounts_opportunity do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :accounts_opportunity
  end
end
