class CreatePuntosDeEntregas < ActiveRecord::Migration
  def self.up
    create_table :puntos_de_entregas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :puntos_de_entregas
  end
end
