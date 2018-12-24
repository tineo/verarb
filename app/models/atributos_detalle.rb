class AtributosDetalle < ActiveRecord::Base
  belongs_to :detalle
  
  def valid?
    # As only the numeric type can fail, we have it easy :)
    if self.tipo == "num"
      unless self.valor == ""
        # Valid: 10, 1.5, 2.33333333
        unless self.valor =~ /^[0-9]+(\.[0-9]+){0,1}$/
          return false
        end
      end
    end
    
    return true
  end
  
  
  def valor_presentable
    if self.tipo == "chk"
      return (self.valor == "" ? "NO" : "SI")
    elsif self.tipo == "com"
      return self.valor.gsub("\n", "<br>\n")
    else
      return self.valor
    end
  end
end
