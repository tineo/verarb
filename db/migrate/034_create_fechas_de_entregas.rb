class CreateFechasDeEntregas < ActiveRecord::Migration
  def self.up
    create_table :fechas_de_entregas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :fechas_de_entregas
  end
end
