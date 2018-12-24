class CreateTerminadosEnPlantas < ActiveRecord::Migration
  def self.up
    create_table :terminados_en_plantas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :terminados_en_plantas
  end
end
