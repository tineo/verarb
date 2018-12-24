class CreateCotizacionDetalles < ActiveRecord::Migration
  def self.up
    create_table :cotizacion_detalles do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :cotizacion_detalles
  end
end
