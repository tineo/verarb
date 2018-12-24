class CreateOpportunitiesContacts < ActiveRecord::Migration
  def self.up
    create_table :opportunities_contacts do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :opportunities_contacts
  end
end
