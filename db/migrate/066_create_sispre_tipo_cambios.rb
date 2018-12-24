class CreateSispreTipoCambios < ActiveRecord::Migration
  def self.up
    create_table :sispre_tipo_cambios do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :sispre_tipo_cambios
  end
end
