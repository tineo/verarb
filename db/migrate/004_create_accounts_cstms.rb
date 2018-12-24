class CreateAccountsCSTMs < ActiveRecord::Migration
  def self.up
    create_table :accounts_cstms do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :accounts_cstms
  end
end
