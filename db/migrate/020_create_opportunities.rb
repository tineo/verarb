class CreateOpportunities < ActiveRecord::Migration
  def self.up
    create_table :opportunities do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :opportunities
  end
end
