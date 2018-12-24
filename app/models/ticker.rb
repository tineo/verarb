class Ticker < ActiveRecord::Base
  set_table_name "ticker"
  
  def self.get
    (Ticker.find :first).content
  end
end
