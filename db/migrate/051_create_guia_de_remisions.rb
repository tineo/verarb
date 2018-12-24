class CreateGuiaDeRemisions < ActiveRecord::Migration
  def self.up
    create_table :guia_de_remisions do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :guia_de_remisions
  end
end
