class CreateTipoDeCambios < ActiveRecord::Migration
  def self.up
    create_table :tipo_de_cambios do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :tipo_de_cambios
  end
end
