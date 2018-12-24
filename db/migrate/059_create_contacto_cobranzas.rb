class CreateContactoCobranzas < ActiveRecord::Migration
  def self.up
    create_table :contacto_cobranzas do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :contacto_cobranzas
  end
end
