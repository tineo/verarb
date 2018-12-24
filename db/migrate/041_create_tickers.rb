class CreateTickers < ActiveRecord::Migration
  def self.up
    create_table :tickers do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :tickers
  end
end
