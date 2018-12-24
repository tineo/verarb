class CreateProyectoFactPriceRedefs < ActiveRecord::Migration
  def self.up
    create_table :proyecto_fact_price_redefs do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :proyecto_fact_price_redefs
  end
end
