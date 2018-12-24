class TipoDeCambio < ActiveRecord::Base
  set_table_name "tipo_de_cambio"
  
  def self.for_today
    tcs = TipoDeCambio.find_by_sql "SELECT * FROM tipo_de_cambio WHERE fecha='#{Date.today}'"
    
    if tcs.empty?
      return 1
    else
      return tcs[0].cambio
    end
  end
  
  
  def self.get_for_date(month, year)
    last_day_of_month = Date.civil(year, month, -1).day
    
    data = {}
    1.upto(last_day_of_month) { |d| data[d] = 0.0 }
    
    tcs = TipoDeCambio.find_by_sql "SELECT * FROM tipo_de_cambio WHERE MONTH(fecha)='#{month}' AND YEAR(fecha)='#{year}' ORDER BY fecha"
    
    tcs.each do |t|
      data[t.fecha.day] = t.cambio
    end
    
    return data
  end
  
  
  def self.update_or_create(year, month, day, cambio)
    fecha = Date.civil(year, month, day)
    
    t = TipoDeCambio.find_by_fecha fecha
    
    if t
      t.cambio = cambio
    else
      t = TipoDeCambio.new
      t.cambio = cambio
      t.fecha  = fecha
    end
    t.save
  end
  
  
  def self.update_with_sispre
    tc = SispreTipoCambio.get_venta_for_today
    
    unless tc == false
      self.update_or_create(Time.now.year, Time.now.month, Time.now.day, tc)
    end
    
    # And yesterday too, sez Javier
    tc = SispreTipoCambio.get_for_date(1.day.ago)
    
    unless tc.nil?
      t = 1.day.ago
      self.update_or_create(t.year, t.month, t.day, tc.Venta_Tip)
    end
    
  end
end
