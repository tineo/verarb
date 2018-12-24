class GuiaNumber < ActiveRecord::Base
  set_table_name "guias_numbers"
  
  def self.peek_next(serie, empresa)
  # Peeks, tells in advance which one is the next number but does not create
  # or reserve it
    (GuiaNumber.find_by_sql "SELECT MAX(numero) AS numero FROM guias_numbers WHERE serie='#{serie}' AND empresa='#{empresa}'").first.numero + 1
  end
  
  
  def self.get_next(serie, empresa)
  # Peeks and pokes!
    n = GuiaNumber.peek_next(serie, empresa)
    
    f = GuiaNumber.new({
      :numero  => n,
      :serie   => serie,
      :empresa => empresa
    })
    f.save
    
    return n
  end
  
  
  def self.reserve_next_as_blank(serie, empresa)
    n = GuiaNumber.get_next(serie, empresa)
    
    g = GuiaDeRemision.new
    g.numero  = n
    g.serie   = serie
    g.empresa = empresa
    # We blank it to set the default values
    g.blank!
  end
  
end
