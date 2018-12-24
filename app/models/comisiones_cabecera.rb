class ComisionesCabecera < ActiveRecord::Base
  has_many :detalles, :class_name => "ComisionesDetalle"
  belongs_to :user
  
  
  def self.calc_start_month
  # Returns the month on which we begin to calculate the Executive's quotas
    a = ComisionesCabecera.find_by_sql "SELECT fecha_origen FROM comisiones_cabeceras ORDER BY fecha_origen DESC LIMIT 1"
    
    if a.empty?
      date = Time.mktime(2008, 11, 1, 0, 0, 0)
    else
      date = (a.first.fecha_origen + 1.month).beginning_of_month
    end
    
    return date
  end
  
  
  def self.pending
    return ComisionesCabecera.find_all_by_fecha_cobrada(nil)
  end
  
  
  def self.comissions_for(date)
    d = date.strftime("%Y-%m-%d 00:00:00")
    
    cc = ComisionesCabecera.find_by_sql "
      SELECT *
        FROM comisiones_cabeceras
       WHERE fecha_cobrada='#{d}'"
    
    return cc
  end
  
  
  def self.completed_comissions_generated_on(date)
    return ComisionesCabecera.find_by_sql "
      SELECT *
        FROM comisiones_cabeceras
       WHERE fecha_origen='#{date.strftime("%Y-%m-%d 00:00:00")}'
         AND fecha_cobrada IS NOT NULL"
  end
end
