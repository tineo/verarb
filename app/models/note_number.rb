class NoteNumber < ActiveRecord::Base
  set_table_name "notes_numbers"
  
  def self.peek_next(type, empresa)
  # Peeks, tells in advance which one is the next number but does not create
  # or reserve it
    (NoteNumber.find_by_sql "SELECT MAX(numero) AS numero FROM notes_numbers WHERE tipo='#{type}' AND empresa='#{empresa}'").first.numero + 1
  end
  
  
  def self.get_next(type, empresa)
  # Peeks and pokes!
    n = NoteNumber.peek_next(type, empresa)
    
    f = NoteNumber.new({
      :numero  => n,
      :tipo    => type,
      :empresa => empresa
    })
    f.save
    
    return n
  end
  
  
  def self.reserve_next_as_blank(type, empresa)
    n = NoteNumber.get_next(type, empresa)
    
    f = NotaDeCredito.new
    f.numero  = n
    f.tipo    = type
    f.empresa = empresa
    f.save
    
    # We blank it to set the default values
    f.blank!
  end
  
  
  def self.unmark_blank(id)
    f = NoteNumber.find id
    f.blank = false
    f.save
  end
  
  
  def self.available_for_new?(number, type, empresa)
    # We check if he's trying to use the next available
    n = NoteNumber.peek_next(type, empresa)
    return true if number == n
    
    # Oh well, then we check if he's trying to use a blank number
    list = NotaDeCredito.find_usable_for_new(type, empresa)
    return list.include?(number)
  end
  
  
end
