class Cuota < ActiveRecord::Base
  belongs_to :user
  
  def self.get_periods
    ps = Cuota.find_by_sql "SELECT DISTINCT MONTH(periodo) AS month, YEAR(periodo) AS year FROM cuotas ORDER BY periodo"
    return ps
  end
end
