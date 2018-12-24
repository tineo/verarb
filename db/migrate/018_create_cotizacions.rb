class CreateCotizacions < ActiveRecord::Migration
  def self.up
    create_table :cotizacions do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :cotizacions
  end
end
