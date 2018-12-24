class Session < ActiveRecord::Base
  
  def self.login(user_id, ip)
    s           = Session.new
    s.user_id   = user_id
    s.remote_ip = ip
    s.action    = "in"
    s.save
  end
  
  
  def self.logout(user_id, ip)
    s           = Session.new
    s.user_id   = user_id
    s.remote_ip = ip
    s.action    = "out"
    s.save
  end
  
end
