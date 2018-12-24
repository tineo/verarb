class CreateFechasDeEntregaLogs < ActiveRecord::Migration
  def self.up
    create_table :fechas_de_entrega_logs do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :fechas_de_entrega_logs
  end
end
