class ApplicationController < ActionController::Base
  before_filter :set_encoding
  #before_filter :check_session_ip
  
  def set_encoding
     headers['Content-Type'] ||= 'text/html'
    if headers['Content-Type'].starts_with?('text/') and !headers['Content-Type'].include?('charset=')
      headers['Content-Type'] += '; charset=iso-8859-1'
    end
  end
  
  
  def check_session_ip
    unless self.controller_name == "exports"
      if session[:user].nil?
        unless self.controller_name == "users" && self.action_name == "login"
          redirect_to :controller => "users", :action => "login"
          return false
        end
      else
        u = User.find session[:user][:id]
        
        if (request.remote_ip == u.last_ip)
          u.last_request = Time.now
          u.save
        else
          session[:user] = nil
          check_authenticated
          return false
        end
        
        # And this is to keep the session from expiring
        session[:user][:ping] = Time.now.to_i
      end
    end
  end
  
  
  def preload_project
  # According to the URL used, creates the @project object. That means, if the
  # URL references the project or the order. Read the code.
    request.path() =~ /^\/(.+?)\//
    url = $1
    id  = params[:id]
    
    begin
      if url == "projects"
        @project = Proyecto.find params[:id]
      elsif url == "orders"
        @project = Proyecto.find_odt params[:id]
      else
        raise "Error preloading Project"
      end
    rescue ActiveRecord::RecordNotFound
      render :action => "not_found"
      return false
    end
    
    # Check the Company
    unless can_see_company? @project.empresa_vendedora
      redirect_to :controller => "dashboard", :action => "index"
    end
    
    # Does it have its Fechas de Entrega complete?
    if !["edit_fechas_de_entrega", "edit_project"].include?(self.action_name)  && @project.fechas_de_entrega.empty? && is_executive?
      redirect_to :controller => "projects", :action => "edit_fechas_de_entrega", :id => @project.id
    end
    
    return true
  end
  
  
  def preload_factura
  # When we call Facturas, we always do it under the "fid" parameter
    @factura = Factura.find params[:fid]
    get_facturation_document_type
    
    # Check the Company
    if can_see_company? @factura.empresa
      return true
    else
      redirect_to :controller => "dashboard", :action => "index"
    end
  end
  
  
  def preload_note
  # When we call Credit Notes, we always do it under the "nid" parameter
    @note = NotaDeCredito.find params[:nid]
    
    # Check the Company
    if can_see_company? @note.empresa
      return true
    else
      redirect_to :controller => "dashboard", :action => "index"
    end
  end
  
  
  def preload_fecha_de_entrega
    begin
      @date = FechasDeEntrega.find params[:fid]
    rescue ActiveRecord::RecordNotFound
      render :action => "not_found"
      return false
    end
    
    unless @project.fechas_de_entrega.include? @date
      raise "Fecha de Entrega doesn't belong to invoked Project"
      return false
    end
    
    return true
  end
  
  
  def get_facturation_document_type
    if params[:type]
      @type = params[:type]
    else
      @type = "f"
    end
    
    if @type == "f"
      @document_label_plural   = "Facturas"
      @document_label_singular = "Factura"
      set_current_tab "facturas"
    else
      @document_label_plural   = "Boletas"
      @document_label_singular = "Boleta"
      set_current_tab "boletas"
    end
  end
  
  
  def get_facturation_document_type_for_notes
    if params[:type]
      @type = params[:type]
    else
      @type = "f"
    end
    
    if @type == "f"
      @document_label_plural   = "Facturas"
      @document_label_singular = "Factura"
    else
      @document_label_plural   = "Boletas"
      @document_label_singular = "Boleta"
    end
  end
  
  
  def check_access
    action = self.action_name
    ok     = false
    
    # DASHBOARD
    if self.controller_name == "dashboard"
      ok = true
    end
    
    # PROJECTS
    if self.controller_name == "projects"
      set_current_tab('projects') if @project.type == "p"
      set_current_tab('orders')   if @project.type == "o"
      
      ok = true if action == "t"
      
      # Read Projects
      if ["projects", "areas", "archive"].include? action
        ok = true if can_access? :projects
      
      # Read Orders
      elsif ["orders", "archive_orders", "print_order"].include? action
        ok = true if can_access? :orders
      
      # Read Projects/Orders
      elsif ["show", "show_details", "show_detail", "show_product", "show_service", "post_message", "get_file", "delete_project_file", "toggle_attached_file"].include? action
        ok = true if (@project.type == "p") && (can_access? :projects)
        ok = true if (@project.type == "o") && (can_access? :orders)
      
      elsif action == "notifications"
        ok = true if (@project.type == "p") && is_supervisor?
        ok = true if (@project.type == "o") && is_supervisor?
      
      # Executive Tasks
      elsif ["new", "edit_metadata", "edit_fechas_de_entrega", "edit_details", "add_product", "add_service", "edit_detail", "edit_product", "edit_service", "delete_detail", "edit_project", "send_to_area", "send_to", "email_cotizacion", "mark_cotization", "cotizacion_sent", "void_order", "invoice", "mark_post_venta", "toggle_urgency", "empty_ruc", "create_gr", "delete_opportunity", "delete_confirmation_doc", "set_standby"].include? action
        ok = true if is_executive?
      
      elsif ["cotization", "view_cotizacion", ].include? action
        ok = true if is_executive? || can_access?(:cotizations)
      
      elsif ["history_of_dates", "change_empresa_or_type"].include? action
        ok = true if is_supervisor?
      
      elsif ["get_confirmation_doc", "confirmation_docs_popup"].include? action
        ok = true if is_executive?
        ok = true if is_operations_validator?
        ok = true if is_facturation?
      
      elsif ["get_costs_doc", "costs_docs_popup"].include? action
        ok = true if is_executive?
        ok = true if is_costs?
      
      # Chief Designer tasks
      elsif ["assign_designer"].include? action
        ok = true if is_chief_designer?
      
      # Design area
      elsif action == "design"
        ok = true if can_access? :design
      
      elsif action == "design_development"
        ok = true if can_access? :design_development
      
      # Designer tasks
      elsif ["notify_design", "notify_design_development"].include? action
        ok = true if is_chief_designer?
        ok = true if is_designer?
      
      # Planning area
      elsif action == "planning"
        ok = true if can_access? :planning
      
      # Planning tasks
      elsif action == "notify_plan"
        ok = true if is_planner?
        ok = true if is_chief_planning?
      
      elsif action == "assign_planner"
        ok = true if is_chief_planning?
      
      # Costs area
      elsif ["costs", "get_costs_file"].include? action
        ok = true if can_access? :costs
        ok = true if is_executive?
        ok = true if is_operations_validator?
      
      # Costs actions
      elsif action == "notify_costs"
        ok = true if is_costs?
      
      # Innovations area
      elsif ["innovations", "get_innovations_file"].include? action
        ok = true if can_access? :innovations
      
      # Installations area
      elsif ["installations", "get_installations_file"].include? action
        ok = true if can_access? :installations
      
      # Production area
      elsif ["production", "production_edit"].include? action
        ok = true if can_access? :production
      
      # Operations area
      elsif ["op_date", "op_date_item"].include? action
        ok = true if is_operations?
        ok = true if is_executive?
        ok = true if is_operations_validator?
      
      elsif ["op_date_modify"].include? action
        ok = true if is_operations?
        ok = true if is_executive?
      
      # Operations tasks
      elsif action == "remove_op"
        ok = true if is_operations?
      
      # Promote stuff
      elsif action == "promote"
        ok = true if is_executive?
      
      elsif action == "confirmation_data_of_order"
        ok = true if is_executive?
        ok = true if is_operations?
        ok = true if is_operations_validator?
      
      # Docs popups
      elsif ["confirmation_docs_popup", "costs_docs_popup"].include? action
        ok = true if is_owner?
        ok = true if is_operations_validator?
      
      # Redefinition of price on an already facturated ODT
      elsif action == "redefine_facturated_price"
        ok = true if is_executive? || is_facturation? || is_supervisor?
      
      elsif action == "variable_cost"
        ok = true if is_supervisor? || is_admin? || is_operations_validator?
      
      # Things that don't require any authorization
      elsif ["panel", "quicksearch", "export_orders", "export_guias", "rebuild_sales_stage_modified", "import_accounts", "import_execs", "unmark_odt_for_export", "do_the_tc_dance", "set_panel_page", "auto_complete_for_account_name", "set_sort_field", "account_blocked"].include? action
        ok = true
      
      end
    end
    
    # CATEGORIES
    if self.controller_name == "categories"
      ok = true if is_admin?
    end
    
    # PRODUCTS
    if self.controller_name == "products"
      if action == "get_file"
        ok = true
      else
        ok = true if is_admin?
      end
    end
    
    # SERVICES
    if self.controller_name == "services"
      ok = true if is_admin?
    end
    
    # FACTURATION
    if self.controller_name == "facturation"
      ok = true if is_facturation?
    end
    
    # NOTES
    if self.controller_name == "notes"
      ok = true if is_facturation?
    end
    
    # USERS
    if self.controller_name == "users"
      if action == "admin_quotas"
        ok = true if is_admin?
      else
        ok = true
      end
    end
    
    # GROUPS
    if self.controller_name == "groups"
      ok = true if is_admin?
    end
    
    # TIPO DE CAMBIO
    if self.controller_name == "tipo_de_cambio"
      ok = true if is_admin?
    end
    
    # ADMIN
    if self.controller_name == "admin"
      ok = true if is_admin?
      ok = true if action == "index" && can_access?(:accounts_extras)
    end
    
    # ROLES
    if self.controller_name == "roles"
      ok = true if is_admin?
    end
    
    # ACCOUNTS
    if self.controller_name == "accounts"
      ok = true if is_admin?
      ok = true if action == "accounts_extras" && can_access?(:accounts_extras)
    end
    
    # VALIDATION OF ORDERS
    if self.controller_name == "projects" && action == "validate_orders"
      ok = true if is_operations_validator?
    end
    
    # REPORTS
    if self.controller_name == "reports"
      ok = true if action == "index"
      ok = true if action == "t"
      ok = true if action == "t2"
      ok = true if action == "odt_consumption"
      
      ok = true if action == "ventas" && can_access?(:reports_ventas)
      ok = true if action == "ventas_details" && can_access?(:reports_ventas)
      
      ok = true if action == "executives_quotas" && can_access?(:reports_ventas)
      ok = true if action == "executives_comissions" && can_access?(:reports_ventas)
      
      ok = true if ["monthly", "monthly_data_accumulated", "monthly_data_by_month", "monthly_data_by_year"].include?(action) && can_access?(:reports_monthly)
      ok = true if action == "account_movement" && can_access?(:reports_account_movement)
      ok = true if action == "commercial_briefing" && can_access?(:reports_commercial_briefing)
      ok = true if action == "design" && can_access?(:reports_design)
      ok = true if action == "facturation_flow" && can_access?(:reports_flow)
      ok = true if action == "facturation_flow_details" && can_access?(:reports_flow)
      ok = true if action == "billing_weekly_flow" && can_access?(:reports_weekly_flow)
      ok = true if action == "notifications" && is_supervisor?
      ok = true if action == "odt_guias" && can_access?(:reports_odt_guia)
      ok = true if action == "truput_estimado_mes" && can_access?(:reports_truput_estimado_mes)
      ok = true if action == "truput_estimado_mes_detalle" && can_access?(:reports_truput_estimado_mes)
      ok = true if action == "estimado_cierre_de_venta" && can_access?(:reports_estimado_cierre_de_venta)
      ok = true if action == "estimado_cierre_de_venta_detalle" && can_access?(:reports_estimado_cierre_de_venta)
      ok = true if action == "facturation_pending" && is_executive? || is_supervisor?
      ok = true if action == "costos_por_odt" && can_access?(:reports_costos_por_odt)
      ok = true if action == "resument_truput_mensual" && can_access?(:reports_resument_truput_mensual)
      ok = true if action == "odts_sin_fecha_cierre" && can_access?(:reports_odts_sin_fecha_cierre)
      ok = true if action == "otras_variables" && can_access?(:reports_otras_variables)
    end
    
    redirect_to :controller => "dashboard", :action => "index" unless ok
  end
  
  
  def preload_guia
    @guia = GuiaDeRemision.find params[:id]
    
    # Check the Company
    if can_see_company? @guia.empresa
      return true
    else
      redirect_to :controller => "dashboard", :action => "index"
    end
  end
  
  
  def check_authenticated
    if session[:user].nil?
      session[:came_from_url] = request.request_uri
      redirect_to :controller => "users", :action => "login"
      return false
    end
  end
  
  
  def role
    return session[:user][:role]
  end
  
  
  def has_this_role?(r)
  # Checks if the user has the role, including Admin
    if r == CRM_ROLE_ADMIN
      return session[:user][:roles].include?(r)
    else
      return session[:user][:role] == r
    end
  end
  
  
  def user_has_more_than_one_role?
    if session[:user][:roles].size > 1
      return true
    else
      return false
    end
  end
  
  
  def can_access?(this)
    if this == :basic
      return true
    elsif this == :admin
      return is_admin?
    else
      return session[:user][:allows].include?(this)
    end
  end
  
  
  def has_access_for(this)
    if can_access?(this)
      return true
    else
      redirect_to :controller => "dashboard", :action => "index"
      return false
    end
  end
  
  
  def is_executive?
    if can_access?(:executive_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_chief_designer?
    if can_access?(:chief_designer_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_designer?
    if can_access?(:designer_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_chief_planning?
    if can_access?(:chief_planning_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_planner?
    if can_access?(:planner_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_costs?
    if can_access?(:costs_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_operations?
    if can_access?(:operations_mob_tasks) || can_access?(:operations_arq_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_operations_mobiliario?
    if can_access?(:operations_mob_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_operations_arquitectura?
    if can_access?(:operations_arq_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_facturation?
    if can_access?(:facturation_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_admin?
    return session[:user].is_vera_admin?
  end
  
  
  def is_printviewer?
    if can_access?(:printviewer_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_supervisor?
    return session[:user].is_vera_supervisor?
  end
  
  
  def is_development?
    if can_access?(:development_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_innovations?
    if can_access?(:innovations_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_installations?
    if can_access?(:installations_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_production?
    if can_access?(:production_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_operations_validator?
    if can_access?(:operations_validator_tasks)
      return true
    else
      return false
    end
  end
  
  
  def is_owner?
    return true if is_admin?
    return true if is_supervisor?
    
    uid = session[:user][:id]
    
    if is_executive?
      return @project.executive.id == uid
    
    elsif is_designer?
      return @project.area.encargado_diseno == uid
    
    elsif is_planner?
      return @project.area.encargado_planeamiento == uid
    
    elsif is_operations?
      return @project.subtipo_nuevo_proyecto_mobiliario? && is_operations_mobiliario?
      return @project.subtipo_nuevo_proyecto_arquitectura? && is_operations_arquitectura?
    
    elsif is_operations_validator?
      return @project.area.en_validacion_operaciones?
    
    # FIXME This is not supposed to be here! The validation is if it's
    # a project owner, not if it has a certain role. This type of validation
    # should be moved to can_access action level
    elsif is_costs? || is_production?
      return true
    
    end
    
    return false
  end
  
  
  def check_is_executive
    unless is_executive?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_is_admin
    unless is_admin?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_is_chief_designer
    unless is_chief_designer?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_is_designer
    unless is_designer?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_is_chief_planning
    unless is_chief_planning?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_is_planner
    unless is_planner?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_is_costs
    unless is_costs?
      redirect_to :controller => "projects", :action => "panel"
    end
  end
  
  
  def check_is_operations
    unless is_operations?
      redirect_to :controller => "projects", :action => "panel"
    end
  end
  
  
  def can_see_design?
    if is_executive? || is_chief_designer? || is_designer?
      return true
    else
      return false
    end
  end
  
  
  def can_see_operations?
    if is_executive? || is_operations?
      return true
    else
      return false
    end
  end
  
  
  def check_can_see_design
    unless can_see_design?
      redirect_to :controller => "projects", :action => "panel"
    end
  end
  
  
  def check_can_see_operations
    unless can_see_operations?
      redirect_to :controller => "projects", :action => "panel"
    end
  end
  
  
  def check_can_notify_design
    unless is_chief_designer? || is_designer?
      redirect_to :controller => "projects", :action => "panel"
    end
  end
  
  
  def check_can_notify_planning
    unless is_chief_planning? || is_planner?
      redirect_to :controller => "projects", :action => "panel"
    end
  end
  
  
  def can_see_costs?
    if is_executive? || is_costs?
      return true
    else
      return false
    end
  end
  
  
  def can_see_planning?
    if is_executive? || is_chief_planning? || is_planner?
      return true
    else
      return false
    end
  end
  
  
  def can_see_cotizations?(p)
    if is_executive?
      return true
    else
      return false
    end
  end
  
  
  def can_see_order?(p)
    if p.con_orden_de_trabajo? && can_access?(:executive_tasks)
      return true
    else
      return false
    end
  end
  
  
  def check_can_see_costs
    unless can_see_costs?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_can_see_planning
    unless can_see_planning?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_cannot_access_if_void
    if @project.anulado?
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_cannot_access_if_not_owner
    if is_owner?
      return true
    else
      redirect_to :controller => "dashboard", :action => "index"
      return false
    end
  end
  
  
  def rmtree(directory)
    Dir.foreach(directory) do |entry|
      next if entry =~ /^\.\.?$/     # Ignore . and .. as usual
      path = directory + "/" + entry
      if FileTest.directory?(path)
        rmtree(path)
      else
        File.delete(path)
      end
    end
  
    Dir.delete(directory)
  end
  
  
  def check_can_access_only_as_project
    # Allows the Methods to be used ONLY if it's a Project
    unless @project.con_orden_de_trabajo?
      return true
    else
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def check_can_access_only_as_order
    # Allows the Methods to be used ONLY if it's an Order
    if @project.con_orden_de_trabajo?
      return true
    else
      redirect_to :controller => "projects", :action => "panel"
      return false
    end
  end
  
  
  def process_date_and_time(form, element)
    date = form.send(element + "_fecha")
    time = form.send(element + "_hora")
    ampm = form.send(element + "_am_pm")
    
    if date == ""
      the_date = nil
    else
      h = time[0,2]
      m = time[2,2]
      
      if (ampm == "PM")
        h = (h.to_i + 12).to_s unless h == "12"
      end
      
      date =~ /^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{2})$/
      the_date = Time::parse("20" + $3 + "-" + $2 + "-" + $1 + "T" + "#{h}:#{m}")
    end
    
    return the_date
  end
  
  
  def process_date_and_hour_2(date, time, ampm)
  # Don't use this anymore, read code-cleanups.txt
    if date == ""
      the_date = nil
    else
      h = time[0,2]
      m = time[2,2]
      
      if (ampm == "PM")
        h = (h.to_i + 12).to_s unless h == "12"
      end
      
      date =~ /^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{2})$/
      the_date = Time::parse("20" + $3 + "-" + $2 + "-" + $1 + "T" + "#{h}:#{m}")
    end
    
    return the_date
  end
  
  
  def load_date_and_time(form, name, date)
    if date.nil?
      fecha = ""
      hora  = ""
      ampm  = ""
    else
      fecha = date.strftime("%d/%m/%y")
      hora  = date.strftime("%I%M")
      ampm  = date.strftime("%p")
    end
    
    form.send("#{name}_fecha=", fecha)
    form.send("#{name}_hora=",  hora)
    form.send("#{name}_am_pm=", ampm)
  end
  
  
  def status_for_this_user(p)
  # Convenience function, returns the status of a project according to this
  # user's role and area. i.e. If it's a chief designer, it returns the
  # status of the design area.
    if is_executive?
      status = p.status
    elsif is_chief_designer? || is_designer?
      status = p.area.estado_diseno
    elsif is_chief_planning? || is_planner?
      status = p.area.estado_planeamiento
    elsif is_costs?
      status = p.area.estado_costos
    elsif is_operations?
      status = p.area.estado_operaciones
    else # generic
      status = p.status
    end
    
    # If the status somehow doesn't exist, we set it to new
    status = E_NUEVO if ESTADOS[status].nil?
    
    return status
  end
  
  
  def current_tab
    session[:current_tab] ||= "dashboard"
  end
  
  
  def set_current_tab(t)
    session[:current_tab] = t
  end
  
  
  def set_tab_projects_for
    set_current_tab("projects")
  end
  
  
  def set_tab_orders_for
    set_current_tab("orders")
  end
  
  
  def set_tab_admin
    set_current_tab("admin")
  end
  
  
  def set_tab_dashboard
    set_current_tab("dashboard")
  end
  
  
  def set_tab_reports
    set_current_tab("reports")
  end
  
  
  def set_order_field_for(tab, field, query)
    if session[:order].nil?
      session[:order] = {
        "projects" => {
          :field => "DEFAULT",
          :query => "DEFAULT"
        },
        "orders" => {
          :field => "DEFAULT",
          :query => "DEFAULT"
        },
        "opportunities" => {
          :field => "DEFAULT",
          :query => "DEFAULT"
        }
      }
    end
    
    session[:order][tab] = {
      :query => query,
      :field => field
    }
  end
  
  
  def get_order_field_for(tab)
    if session[:order][tab].nil?
     set_order_field_for tab, "DEFAULT", "DEFAULT"
   else
     session[:order][tab]
   end
  end
  
  
  def format_price(number)
    return "" if number.nil?
    
    parts = ("%0.2f" % number).to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    parts.join "."
  end
  
  
  def format_report_price(number)
  # Report prices have no decimal part
    return "" if number.nil?
    
    number.round.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end
  
  
  def verbose_odt_price(p)
    if p.monto_de_venta.nil?
      return "N/A"
    elsif p.monto_de_venta == 0
      return "(Precio por definir)"
    else
      return currency(p.moneda_odt) + format_price(p.monto_de_venta) + " (" + (p.incluye_igv_odt? ? "Incl. IGV" : "No incl. IGV") + ")"
    end
  end
  
  
  def verbose_odt_original_price(p)
    if p.monto_odt.nil?
      return "N/A"
    elsif p.monto_odt == 0
      return "(Precio por definir)"
    else
      return currency(p.moneda_odt) + format_price(p.monto_odt) + " (" + (p.incluye_igv_odt? ? "Incl. IGV" : "No incl. IGV") + ")"
    end
  end
  
  
  def currency(c)
    (c == "S" ? "S/." : "$")
  end
  
  
  def multirow_load(form, *parameters)
  # Creates, processes and returns a multirow array
  # Delete button must be named "row_delete"
  # Add button must be named "row_add"
    result = []
    
    # Build the delete list
    if params[:row_delete] != nil && params[:row_delete].class.to_s == "HashWithIndifferentAccess" && params[:row_delete].size > 0
      delete_list = params[:row_delete].keys
    else
      delete_list = []
    end
    
    keys = parameters.inject([]) do |m, k, v|
      m << k.to_s
    end
    
    # Check if there's at least one of the parameters in the Rails params thing
    if (params.keys & keys)
      # Ok, let's get to work
      # First, we create a hash with the expected parameters, or empty ones
      # if they don't exist
      values = {}
      
      keys.each do |k|
        if params[k] != nil && params[k].class.to_s == "HashWithIndifferentAccess" && params[k].size > 0
          values[k] = params[k]
        else
          values[k] = HashWithIndifferentAccess.new
        end
      end
      
      # Ok, let's build the array!
      values[keys.first].each_with_index do |v, i|
        i = i.to_s
        
        next if delete_list.include? i
        
        f = Fionna.new(form)
        
        keys.each do |k|
          f.send("#{k}=", values[k][i])
        end
        
        result << f
      end
      
      if result == []
        # We don't want an empty result -- there must be at least one row
        result = [] << Fionna.new(form)
      end
    else
      result = [] << Fionna.new(form)
    end
    
    if params[:row_add]
      result << Fionna.new(form)
    end
    
    return result
  end
  
  
  def multirow_validate(rows)
    valid = true
    
    rows.each do |r|
      valid = false unless r.valid?
    end
    
    return valid
  end
  
  
  def init_filter(section)
    session[:panel_filter]          ||= {}
    session[:panel_filter][section] ||= {}
  end
  
  
  def set_filter(section, parameters)
    init_filter(section)
    session[:panel_filter][section] = parameters
    
    # This is a special case for the Projects/Orders/Opp form, where we load
    # the Account name from that ajaxy thing
    if ["projects", "orders", "opportunities"].include? section
      session[:panel_filter][section][:client] = params[:account][:name]
    end
  end
  
  
  def get_filter(section)
    init_filter(section)
    return session[:panel_filter][section]
  end
  
  
  def reset_filter(section)
    init_filter(section)
    session[:panel_filter][section] = {}
  end
  
  
  def filter_empty?(section)
    init_filter(section)
    return session[:panel_filter][section] == {}
  end
  
  
  def super_auto_complete_for_account_name
    @accounts = Account.find :all, :conditions => [ "LOWER(name) LIKE ? AND deleted='0'", ('%' + params[:account][:name].downcase + '%')], :order => 'name ASC', :limit => 8
    render :partial => 'accounts/auto_complete_account'
  end
  
  
  def copy_data_file(file, path)
    File.open(path + Time.now.to_i.to_s + '-' + file.original_filename, "w") { |f| f.write(file.read) }
  end
  
  
  def send_data_file_to_browser(path, fid)
    fid  = fid.gsub /\//, ''
    file = path + fid
    
    if File.exists?(file)
      name = File.real_filename(fid)
      
      send_data(File.read(file),
        :filename    => name,
        :type        => "application/octet-stream",
        :disposition => "attachment; filename=" + CGI.escape(name))
    end
  end
  
  
  def delete_data_file(path, fid)
    fid  = fid.gsub /\//, ''
    file = path + fid
    
    File.delete(file) if File.exists?(file)
  end
  
  
  def get_condition_for_form_date_range(start_month, start_year, end_month, end_year, field)
    # Start Date
    if (start_month == "-1" && start_year != "-1")
      # He chose only year and no month, this means to consider
      # the start of the whole year
      start_date = Time.mktime(start_year, 1, 1)
    elsif (start_month != "-1" && start_year != "-1")
      # He chose year and month
      start_date = Time.mktime(start_year, start_month, 1)
    else
      # He chose some other thing which I can't think of
      start_date = false
    end
    
    # End Date
    if (end_month == "-1" && end_year != "-1")
      end_date = Time.mktime(end_year, 12, 31, 23, 59, 59)
    elsif (end_month != "-1" && end_year != "-1")
      # He chose year and month
      end_date = Time.mktime(end_year, end_month, Date.civil(end_year.to_i, end_month.to_i, -1).day, 23, 59, 59)
    else
      # He chose some other thing which I can't think of
      end_date = false
    end
    
    start_date  = start_date.strftime("%Y-%m-%d 00:00:00") if start_date
    end_date    = end_date.strftime("%Y-%m-%d 23:59:59") if end_date
    conditions  = ""
    
    if start_date && end_date
      conditions = " AND #{field} BETWEEN '#{start_date}' AND '#{end_date}' "
    elsif start_date && !end_date
      conditions = " AND #{field} >= '#{start_date}' "
    elsif !start_date && end_date
      conditions = " AND #{field} <= '#{end_date}' "
    end
    
    return conditions
  end
  
  
  def rescue_action_in_public(exception)
    @exception = exception
    
    render :file => RAILS_ROOT + "/public/500.html"
  end
  
  
  def can_see_company?(c)
    return session[:user][:companies].include?(c.to_i)
  end
  
  
  def companies_sql_list
  # Returns a SQL list of the Companies the logged-in user has access to
    return "('" + session[:user][:companies].join("', '") + "')"
  end
  
  
  def set_companies_for(form, no_unselected = nil)
  # Autosets the OHash of Companies this person can see
    r = OHash.new
    
    r["-1"] = "[Elija una empresa]" unless no_unselected
    
    session[:user][:companies].each do |c|
      r[c.to_s] = EMPRESA_VENDEDORA[c.to_i]
    end
    
    @form.set_property_of :empresa_vendedora, { "options" => r }
  end
  
  
end
