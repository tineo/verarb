class CreateAtributos < ActiveRecord::Migration
  def self.up
    create_table :atributos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :atributos
  end
end
