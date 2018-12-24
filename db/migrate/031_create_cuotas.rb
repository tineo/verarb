class CreateCuotas < ActiveRecord::Migration
  def self.up
    create_table :cuotas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :cuotas
  end
end
