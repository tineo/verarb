class SispreTipoCambio < ActiveRecord::Base
  set_table_name "mt_Tipos_Cambio"
  
  def self.get_for_date(date)
    tc = (self.find_by_sql "SELECT * FROM mt_Tipos_Cambio WHERE Fecha_Tip='#{date.strftime("%Y-%m-%d")}'").first
    
    if tc.nil?
      raise "SispreTipoCambio: No existe tipo de cambio para la fecha #{date.short_format}"
    else
      return tc
    end
  end
  
  
  def self.get_venta_for_today
    c = self.get_for_date(Time.today)
    
    return false if c.nil?
    return c.Venta_Tip.to_f
  end
end
