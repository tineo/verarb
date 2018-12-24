class CreateNoteNumbers < ActiveRecord::Migration
  def self.up
    create_table :note_numbers do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :note_numbers
  end
end
