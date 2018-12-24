class FacturaNumber < ActiveRecord::Base
  set_table_name "facturas_numbers"
  
  def self.peek_next(type, empresa)
  # Peeks, tells in advance which one is the next number but does not create
  # or reserve it
    (FacturaNumber.find_by_sql "SELECT MAX(numero) AS numero FROM facturas_numbers WHERE tipo='#{type}' AND empresa='#{empresa}'").first.numero + 1
  end
  
  
  def self.get_next(type, empresa)
  # Peeks and pokes!
    n = FacturaNumber.peek_next(type, empresa)
    
    f = FacturaNumber.new({
      :numero  => n,
      :tipo    => type,
      :empresa => empresa
    })
    f.save
    
    return n
  end
  
  
  def self.reserve_next_as_blank(type, empresa)
    n = FacturaNumber.get_next(type, empresa)
    
    f = Factura.new
    f.numero  = n
    f.tipo    = type
    f.empresa = empresa
    f.save
    
    # We blank it to set the default values
    f.blank!
  end
  
  
  def self.unmark_blank(id)
    f = FacturaNumber.find id
    f.blank = false
    f.save
  end
  
  
  def self.available_for_new?(number, type, empresa)
    # We check if he's trying to use the next available
    n = FacturaNumber.peek_next(type, empresa)
    return true if number == n
    
    # Oh well, then we check if he's trying to use a blank number
    list = Factura.find_usable_for_new(type, empresa)
    return list.include?(number)
  end
  
  
  def self.encode(number, type, empresa)
    return type + empresa.to_s + number.to_s.rjust(9, "0")
  end
  
  
  def self.decode(id)
    return nil unless id.length == 11
    
    return {
      :type    => id[0..0],
      :empresa => id[1..1].to_i,
      :number  => id[2..-1].to_i
    }
  end
end
