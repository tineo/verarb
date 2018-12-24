class CreateDetalles < ActiveRecord::Migration
  def self.up
    create_table :detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :detalles
  end
end
