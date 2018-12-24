class CreateGuiaNumbers < ActiveRecord::Migration
  def self.up
    create_table :guia_numbers do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :guia_numbers
  end
end
