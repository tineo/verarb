class CreateNotaDeCreditos < ActiveRecord::Migration
  def self.up
    create_table :nota_de_creditos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :nota_de_creditos
  end
end
