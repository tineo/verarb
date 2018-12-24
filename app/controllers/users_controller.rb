class UsersController < ApplicationController
  before_filter :check_access
  
  def login
    session[:user] = nil
    
    @form = Fionna.new("login")
    
    @showlogin_error_msg = false
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        login_ok = false
        
        if u = User.authenticate(@form.username, Digest::MD5.hexdigest(@form.password))
          # Check for internal/external access
          if request.remote_ip =~ /^192/
            login_ok = true
          else
            login_ok = true if u.has_external_access?
          end
        end
        
        if login_ok
          login_ok = false if u.companies.nil? || u.companies.empty?
        end
        
        if login_ok
          roles = u.get_roles
          
          if roles.empty?
            login_ok = false
          end
        end
        
        
        # ...FINALLY
        if login_ok
          # Ok, let's login and it all
          u.last_ip      = request.remote_ip
          u.last_request = Time.now
          u.logged_in    = true
          u.save
          
          session[:user]      = u
          session[:user][:ip] = request.remote_ip
          
          # Roles
          session[:user][:roles] = roles
          session[:user][:role]  = roles.first
          
          session[:user][:allows] = User.get_allows(roles.first.id)
          
          # Empresas
          session[:user][:companies] = []
          
          u.companies.each do |c|
            session[:user][:companies] << c.empresa_id
          end
          
          session[:order] = {
            "projects" => {
              :field => "DEFAULT",
              :query => "DEFAULT"
            },
            "orders" => {
              :field => "DEFAULT",
              :query => "DEFAULT"
            }
          }
          
          session[:panel_page] = {
            "projects" => 1,
            "orders"   => 1,
            "guias"    => 1,
            "facturas" => 1,
            "boletas"  => 1,
          }
          
          Session.login(u.id, request.remote_ip)
          
          if session[:came_from_url]
            url = session[:came_from_url]
            session[:came_from_url] = nil
            redirect_to url
          else
            redirect_to :controller => "dashboard", :action => "index"
          end
        
        else
          # Sorry, show the error message
          @show_login_error_msg = true
          render :layout => false
        end
      else
        render :layout => false
      end
    else
      render :layout => false
    end
  end
  
  
  def change_role
    if params[:id]
      role = params[:id]
      
      session[:user][:roles].each do |r|
        if r.id == role.to_i
          session[:user][:role]   = r 
          session[:user][:allows] = User.get_allows(r.id)
        end
      end
      
      redirect_to :controller => "dashboard", :action => "index"
    end
  end
  
  
  def menuarrow
    redirect_to "/javascripts/jscalendar-1.0/menuarrow.gif"
  end
  
  
  def admin_quotas
    set_current_tab "admin"
    
    @periods = Cuota.get_periods
  end
  
  
  def admin_quotas_entry
    @dateform = Fionna.new "admin_quotas_entry"
    @form     = Fionna.new "admin_quotas"
    @execs    = User.list_of :executives
    
    @month = (params[:m] || Time.now.month).to_i
    @year  = (params[:y]  || Time.now.year).to_i
    
    @data = {}
    
    @execs.each do |e|
      cuota = e.quota_on(@year, @month)
      if cuota.nil?
        q = b = c = "0.00"
      else
        q = "%0.2f" % cuota.cuota
        b = "%0.2f" % cuota.bonificacion
        c = "%0.2f" % cuota.comision
      end
      
      @data[e.id] = {
        :quota     => q,
        :bonus     => b,
        :comission => c,
        :error     => ""
      }
    end
    
    if request.post?
      perfect    = true
      quotas     = params[:quota]
      comissions = params[:comission]
      bonuses    = params[:bonus]
      
      @dateform.load_values params
      if @dateform.valid?
        @month = @dateform.month
        @year  = @dateform.year
      else
        perfect = false
      end
      
      quotas.each do |i, q|
        unless @data[i].nil?
          @form.quota          = q
          @data[i][:quota]     = q
          
          c                    = comissions[i]
          @form.comission      = c
          @data[i][:comission] = c
          
          b                    = bonuses[i]
          @form.bonus          = b
          @data[i][:bonus]     = b
          
          if @form.valid?
            user = User.find i
            
            if user
              cuota              = user.new_quota_on(@year, @month)
              cuota.cuota        = q
              cuota.comision     = c
              cuota.bonificacion = b
              cuota.save
            end
          else
            error_msg  = ""
            error_msg += "Error en Cuota<br>" unless @form.e(:quota) == ""
            error_msg += "Error en Comisi&oacute;n<br>" unless @form.e(:comission) == ""
            error_msg += "Error en Bonificaci&oacute;n<br>" unless @form.e(:bonus) == ""
            
            @data[i][:error] = error_msg
            
            perfect = false # Boo!
          end
        end
      end
      
      redirect_to :controller => "users", :action => "admin_quotas" if perfect
    
    else # GET REQUEST
      @dateform.month = @month
      @dateform.year  = @year
    end
  end

  
  def logout
    u = User.find session[:user][:id]
    
    u.logged_in = false
    u.save
    
    if session[:user]
      Session.logout(session[:user][:id], request.remote_ip)
      
      session[:user]       = nil
      session[:order]      = nil
      session[:panel_page] = nil
    end
    
    redirect_to :action => "login"
  end
end
