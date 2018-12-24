class AdminController < ApplicationController
  before_filter :set_tab_admin
  before_filter :check_access
  
  def admin
    set_current_tab "admin"
  end
  
  
  def list_admin
    set_current_tab "admin"
    
    if params[:lid]
      @lid = params[:lid]
    else
      @lid = "void_odt"
    end
    
    # FIXME: We should check if @lid is included into the NOTIFICACION array
    
    if request.post?
      uids = params[:uids]
      
      NotificationList.destroy_all ["list=?", @lid]
      
      uids.each do |u|
        new = NotificationList.new
        new.user_id = u
        new.list    = @lid
        new.save
      end
      
      redirect_to :controller => "admin", :action => "list_admin", :lid => @lid
    end
    
    @users = User.full_list
    list   = User.notification_list_of(@lid)
    
    @list = []
    
    list.each do |l|
      @list << l.id
    end
  end
  
  
  def ticker
    @form = Fionna.new "ticker"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        Ticker.delete_all
        t = Ticker.new({ :content => @form.content })
        t.save
        
        redirect_to :controller => "admin", :action => "index"
      end
    else
      t             = Ticker.find :first
      @form.content = t.content
    end
  end
  
  
  def passwords
    @passwords = Password.read
    
    if request.post?
      @passwords.keys.each do |k|
        k5 = Digest::MD5.hexdigest(k)
        unless params[k5].nil? || params[k5].empty?
          @passwords[k] = params[k5]
        end
      end
      Password.write(@passwords)
      redirect_to :controller => "admin", :action => "passwords"
    end
  end
  
  
  def import_sispre
    @ok = system(RAILS_ROOT + "/script/sispre/import.rb")
  end
  
  
  def insumos_percent
    @form = Fionna.new "insumos_percent"
    
    if request.post?
      @form.load_values params
      
      Proyecto.set_insumos_percent(@form.percent)
      redirect_to :controller => "admin", :action => "insumos_percent"
    else
      @form.percent = Proyecto.insumos_percent.to_s
    end
  end
  
  
  def update_variable_costs_cache
    if params[:update]
      Proyecto.update_variable_costs
    end
  end
  
end
