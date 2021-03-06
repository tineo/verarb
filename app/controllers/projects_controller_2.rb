class ProjectsController < ApplicationController
  before_filter :preload_project, :only => ["post_message", "costs", "planning", "show_detail", "show_details", "delete_detail", "show", "edit_account", "edit_project", "send_to_area", "assign_designer", "notify_design", "notify_design_development", "areas", "send_to", "assign_planner", "notify_plan", "notify_costs", "get_file", "get_costs_file", "get_innovations_file", "edit_metadata", "delete_project_file", "toggle_attached_file", "confirmation_data_of_order", "void_order", "print_order", "planning", "cotization", "view_cotizacion", "email_cotizacion", "cotizacion_sent", "promote", "invoice", "edit_details", "add_product", "add_service", "edit_detail", "design", "design_development", "planning", "costs", "innovations", "mark_post_venta", "op_accept_date", "op_date", "op_date_item", "op_date_modify", "toggle_urgency", "history_of_dates", "create_gr", "confirmation_doc", "delete_opportunity", "confirmation_docs_popup", "get_confirmation_doc", "delete_confirmation_doc", "change_empresa_or_type", "notifications", "redefine_facturated_price", "costs_docs_popup", "get_costs_doc", "delete_costs_doc" "variable_cost", "account_blocked", "set_standby", "installations", "get_installations_file", "edit_fechas_de_entrega", "production", "production_edit"]
  
  before_filter :preload_fecha_de_entrega, :only => ["op_date_item", "op_date_modify", "production_edit"]
 
  before_filter :check_access
  
  before_filter :check_cannot_access_if_void, :only => ["edit_details", "add_product", "add_service", "delete_detail", "edit_account", "edit_project", "send_to_area", "assign_designer", "notify_design", "post_message", "send_to", "assign_planner", "notify_plan", "notify_costs", "email_cotizacion", "edit_metadata", "delete_project_file", "mark_cotizacion", "promote", "toggle_attached_file", "mark_post_venta", "op_accept_date", "op_date", "toggle_urgency", "create_gr", "invoice", "delete_opportunity", "redefine_facturated_price", "production_edit"]
  before_filter :check_can_access_only_as_order, :only => ["void_order", "invoice", "mark_post_venta", "toggle_urgency", "create_gr", "redefine_facturated_price", "variable_cost", "set_standby", "production", "production_edit"]
  before_filter :check_cannot_access_if_not_owner, :only => ["post_message", "delete_detail", "edit_account", "edit_project", "send_to_area", "assign_designer", "notify_design", "areas", "send_to", "assign_planner", "notify_plan", "notify_costs", "edit_metadata", "delete_project_file", "toggle_attached_file", "void_order", "cotization", "view_cotizacion", "promote", "invoice", "edit_details", "add_product", "add_service", "edit_detail", "mark_post_venta", "op_accept_date", "op_date", "op_date_modify", "toggle_urgency", "create_gr", "delete_opportunity", "delete_confirmation_doc",  "change_empresa_or_type", "redefine_facturated_price", "variable_cost", "account_blocked", "set_standby", "production", "production_edit"]
  
  
  def projects
    set_current_tab "projects"
    core
  end
  
  
  def orders
    set_current_tab "orders"
    core
  end
  
  
  def panel
    unless ["projects", "orders"].include? current_tab
      set_current_tab "projects"
    end
    
    redirect_to :controller => "projects", :action => current_tab
  end
  
  
  def core
    tab            = current_tab
    condition_vars = []
    
    # Conditions for everybody
    if tab == "projects"
      conditions = "opportunities.sales_stage<> 'Closed Lost' AND NOT #{SQL_VERA_DELETED} AND empresa_vendedora IN #{companies_sql_list}"
      
      @order = get_order_field_for "projects"
      order  = @order[:query]
      
      if order == "DEFAULT"
        if is_operations?
          order = "proyecto_areas.ingreso_operaciones DESC"
        else
          order = "fecha_creacion_proyecto DESC"
        end
      elsif order == "ID"
        order = "proyectos.id DESC"
      end
    else # Orders
      conditions = "NOT #{SQL_VERA_DELETED} AND proyectos.con_orden_de_trabajo='1' AND empresa_vendedora IN #{companies_sql_list}"
      
      @order = get_order_field_for "orders"
      order  = @order[:query]
      
      if order == "DEFAULT" || order == "ID"
        order = "orden_id DESC"
      end
    end
    
    if is_executive?
      conditions = conditions
      
      if tab == "projects"
        @panel_headers = PANEL_EXECUTIVE_PROJECTS
      else
        @panel_headers = PANEL_EXECUTIVE_ORDERS
      end
      
      if is_supervisor?
        @projects_to_be_promoted = Proyecto.orders_to_be_created :all if tab == "orders"
        @opportunities = Opportunity.list_new if tab == "projects"
      else
        @projects_to_be_promoted = Proyecto.orders_to_be_created session[:user][:id] if tab == "orders"
        @opportunities = Opportunity.list_new_for(session[:user][:id]) if tab == "projects"
        
        conditions = conditions + " AND opportunities.assigned_user_id='" + session[:user][:id] + "'"
      end
     
    elsif is_chief_designer?
      conditions += "AND proyecto_areas.en_diseno='1' AND proyecto_areas.estado_diseno<>'" + E_DISENO_APROBADO.to_s + "'"
      @panel_headers = PANEL_CHIEF_DESIGNER
    
    elsif is_designer?
      conditions += "AND proyecto_areas.en_diseno='1' AND proyecto_areas.estado_diseno<>'" + E_DISENO_APROBADO.to_s + "' AND proyecto_areas.encargado_diseno='" + session[:user][:id] + "'"
      @panel_headers = PANEL_DESIGNER
    
    elsif is_chief_planning?
      conditions += "AND proyecto_areas.en_planeamiento='1' AND proyecto_areas.estado_planeamiento<>'" + E_PLANEAMIENTO_TERMINADO.to_s + "'"
      @panel_headers = PANEL_CHIEF_PLANNING
    
    elsif is_planner?
      conditions += "AND proyecto_areas.en_planeamiento='1' AND proyecto_areas.estado_planeamiento<>'" + E_PLANEAMIENTO_TERMINADO.to_s + "' AND proyecto_areas.encargado_planeamiento='" + session[:user][:id] + "'"
      @panel_headers = PANEL_PLANNER
    
    elsif is_costs?
      conditions += "AND proyecto_areas.en_costos='1' AND proyecto_areas.estado_costos<>'" + E_COSTOS_TERMINADO.to_s + "'"
      @panel_headers = PANEL_COSTS
    
    elsif is_operations_mobiliario?
      conditions += "AND proyecto_areas.en_operaciones='1' AND proyectos.subtipo_nuevo_proyecto='#{SUBTIPO_NUEVO_PROYECTO_MOBILIARIO}' AND proyecto_areas.estado_operaciones<>'" + E_OPERACIONES_TERMINADO.to_s + "'"
      @panel_headers = PANEL_OPERATIONS
    
    elsif is_operations_arquitectura?
      conditions += "AND proyecto_areas.en_operaciones='1' AND proyectos.subtipo_nuevo_proyecto='#{SUBTIPO_NUEVO_PROYECTO_ARQUITECTURA}' AND proyecto_areas.estado_operaciones<>'" + E_OPERACIONES_TERMINADO.to_s + "'"
      @panel_headers = PANEL_OPERATIONS
    
    elsif is_facturation?
      @panel_headers = PANEL_FACTURATION
    
    elsif is_development?
      conditions += "AND proyecto_areas.en_desarrollo='1' AND proyecto_areas.estado_diseno<>'" + E_DISENO_APROBADO.to_s + "'"
      @panel_headers = PANEL_GENERIC_PROJECTS
      
    elsif is_innovations?
      conditions += "AND proyecto_areas.en_innovaciones='1'"
      @panel_headers = PANEL_GENERIC_PROJECTS
      
    elsif is_installations?
      conditions += "AND proyecto_areas.en_instalaciones='1' AND proyecto_areas.estado_instalaciones='" + E_INSTALACIONES_EN_PROCESO.to_s + "'"
      @panel_headers = PANEL_INSTALLATIONS
    
    elsif is_operations_validator?
      conditions += "AND proyecto_areas.en_validacion_operaciones='1'"
      @panel_headers = PANEL_GENERIC_PROJECTS
    
    else # teh generic!
      if tab == "projects"
        @panel_headers = PANEL_GENERIC_PROJECTS
      else
        @panel_headers = PANEL_GENERIC_ORDERS
      end
    end
    
    # Now, let's go with da form
    @form = Fionna.new "panel"
    
    # We process the form and filter out projects here
    reset_filter(tab) if params[:reset_filters]
    set_filter(tab, params) if params[:q]
    
    @form.load_values get_filter(tab)
    
    if @form.valid?
      # The filters!
      
      # Filter by Client/Account
      unless @form.client == ""
        a = Account.sql_search(@form.client)
        
        if a
          conditions     += " AND proyectos.account_id IN #{a} AND accounts.deleted='0'"
          condition_vars << @form.client
        end
      end
      
      # Filter by Status
      unless @form.status == "-1"
        st = @form.status.to_i
        
        if st == E_NUEVO
          area = "ejecutivo"
        elsif [E_DISENO_EN_PROCESO, E_DISENO_SIN_ASIGNAR, E_DISENO_POR_APROBAR, E_DISENO_OBSERVADO, E_DISENO_APROBADO].include? st
          area = "diseno"
        elsif [E_PLANEAMIENTO_SIN_ASIGNAR, E_PLANEAMIENTO_POR_APROBAR, E_PLANEAMIENTO_EN_PROCESO, E_PLANEAMIENTO_OBSERVADO,E_PLANEAMIENTO_TERMINADO].include? st
          area = "planeamiento"
        elsif [E_COSTOS_EN_PROCESO, E_COSTOS_TERMINADO].include? st
          area = "costos"
        elsif [E_OPERACIONES_EN_PROCESO, E_OPERACIONES_REDEF_WAITING_OP, E_OPERACIONES_REDEF_WAITING_EX, E_OPERACIONES_TERMINADO].include? st
          area = "operaciones"
        end
        
        conditions += " AND proyecto_areas.estado_#{area}='#{@form.status}'"
      end
      
      # Filter by Executive
      unless @form.executive == "-1"
        conditions += " AND opportunities.assigned_user_id='#{@form.executive}'"
      end
      
      # Filter by Designer
      unless @form.designer == "-1"
        conditions += " AND proyecto_areas.encargado_diseno='#{@form.designer}'"
      end
      
      # Filter by Creation Date (both for Projects and Orders)
      if tab == "projects"
        field = "proyectos.fecha_creacion_proyecto"
      else
        field = "proyectos.fecha_creacion_odt"
      end
      
      conditions += get_condition_for_form_date_range(@form.creado_start_month, @form.creado_start_year, @form.creado_end_month, @form.creado_end_year, field)
      
      # Filter by Date of Entrega
      # We ignore this if the user has unchecked Con Fecha de Entrega
      if ["1", "-1"].include? @form.con_fecha_de_entrega
        conditions += get_condition_for_form_date_range(@form.entrega_start_month, @form.entrega_start_year, @form.entrega_end_month, @form.entrega_end_year, "proyectos.fecha_de_entrega_odt")
      else
        conditions += " AND proyectos.fecha_de_entrega_odt IS NULL"
      end
      
      # Filter by ODT
      if tab == "projects" && @form.con_orden_de_trabajo != "-1"
        conditions += " AND con_orden_de_trabajo='#{@form.con_orden_de_trabajo}'"
      end
      
      # Filter by Void
      unless @form.anulado == "-1"
        conditions += " AND anulado='#{@form.anulado}'"
      end
      
      # Filter by Postvendido
      unless @form.postvendido == "-1"
        conditions += " AND postvendido='#{@form.postvendido}'"
      end
     
      # Filter by Autorizado para Facturar
      unless @form.autorizado_para_facturar == "-1"
        conditions += " AND autorizado_para_facturar='#{@form.autorizado_para_facturar}'"
      end
      
      # Filter by Estado Facturacion
      unless @form.status_facturacion == "-1"
        if @form.status_facturacion == F_NO_FACTURABLE
          conditions += " AND tipo_proyecto<>'#{T_NUEVO_PROYECTO}'"
        elsif @form.status_facturacion == F_POR_FACTURAR
          conditions += " AND status_facturacion='#{F_POR_FACTURAR}' AND tipo_proyecto='#{T_NUEVO_PROYECTO}'"
        elsif @form.status_facturacion == F_FACTURA_PARCIAL
          conditions += " AND status_facturacion='#{F_FACTURA_PARCIAL}' AND tipo_proyecto='#{T_NUEVO_PROYECTO}'"
        elsif @form.status_facturacion == F_FACTURA_TOTAL
          conditions += " AND status_facturacion='#{F_FACTURA_TOTAL}' AND tipo_proyecto='#{T_NUEVO_PROYECTO}'"
        end
      end
      
      # Filter by Estado Cobranza
      unless @form.status_cobranza == "-1"
        if @form.status_cobranza == C_POR_COBRAR
          conditions += " AND status_cobranza='#{C_POR_COBRAR}' AND tipo_proyecto='#{T_NUEVO_PROYECTO}'"
        elsif @form.status_cobranza == C_COBRADO
          conditions += " AND status_cobranza='#{C_COBRADO}' AND tipo_proyecto='#{T_NUEVO_PROYECTO}'"
        end
      end
      
      # Filter by Factura Emmitted day
      emitted_condition = get_condition_for_form_date_range(@form.factura_start_month, @form.factura_start_year, @form.factura_end_month, @form.factura_end_year, "fecha_emision")
      
      unless emitted_condition == ""
        # Ok, he's trying to filter by this. What we do is do a query for
        # Project IDs which match having Facturas with this Emission date.
        # We build a list of these IDs and add them to our current condition
        # string
        ofs = OrdenesFacturas.find_by_sql "
          SELECT DISTINCT ordenes_facturas.proyecto_id
            FROM ordenes_facturas,
                 facturas
           WHERE ordenes_facturas.factura_id=facturas.id
                 #{emitted_condition}
                 AND facturas.anulada='0'
                 AND facturas.en_blanco='0'
        "
        
        if ofs.size > 0
          filter_list = []
          
          ofs.each do |of|
            filter_list << of.proyecto_id
          end
          
          filter_list = filter_list.join(",")
          
          # ...and so!
          conditions += " AND proyecto_id IN (#{filter_list})"
        else
          # No emitted Facturas found in that date! We give him an impossible
          # condition to get empty results
          conditions += " AND 1=2"
        end
      end
    end
    
    # Show all?
    if params[:show_all]
      @show_all = true
    else
      @show_all = false
    end
    
    # Build the SQL thing
    pre_sql = "FROM proyectos,
                    proyecto_areas,
                    opportunities,
                    accounts
              WHERE proyecto_areas.proyecto_id=proyectos.id
                AND proyectos.opportunity_id=opportunities.id
                AND proyectos.account_id=accounts.id
                AND " + conditions + " "
    
    if @show_all
      limit_offset = ""
    else
      # Find out the total number of projects found
      sql   = "SELECT COUNT(proyectos.id) AS total " + pre_sql
      total = Proyecto.find_by_sql([sql] + condition_vars)[0].total.to_i
      
      # Pages, dude
      @total_pages = (total / 25).ceil + 1
      @page        = session[:panel_page][tab] || 1
      @page        = @total_pages if @page > @total_pages
      limit_offset = " LIMIT 25 OFFSET " + ((@page - 1) * 25).to_s
    end
    
    # Finally!
    if is_executive? && tab == "orders"
      sql       = "SELECT proyectos.* " + pre_sql + "ORDER BY " + order + limit_offset
      @projects = Proyecto.find_by_sql [sql] + condition_vars
      
    elsif is_operations? && tab == "projects"
      sql       = "SELECT proyectos.* " + pre_sql + " AND notificado_como_venta_asegurada='0' " + "ORDER BY " + order + limit_offset
      @projects = Proyecto.find_by_sql [sql] + condition_vars
      
    else
      sql       = "SELECT proyectos.* " + pre_sql + "ORDER BY " + order + limit_offset
      @projects = Proyecto.find_by_sql [sql] + condition_vars
    end
    
    render :action => "core"
  end
  
  
  def switch_to
    r = params[:rid]
    
    if TABS.include?
      if r == "projects"
        set_current_tab r
        redirect_to :controller => "projects", :action => "panel"
      elsif r == "orders"
        set_current_tab r
        redirect_to :controller => "projects", :action => "panel"
      else
        set_current_tab r
        redirect_to :controller => "dashboard", :action => "index"
      end
    end
  end
  
  
  def set_sort_field
    f   = params[:field]
    tab = params[:tab]
    
    if f == "ID"
      query = "ID"
    
    elsif f == "Propuesta"
      query = "opportunities.name ASC" # Propuesta
    
    elsif f == "Creado"
      # Creado
      if is_executive?
        if tab == "projects"
          query = "proyectos.fecha_creacion_proyecto DESC"
        else
          query = "proyectos.fecha_creacion_odt DESC"
        end
      elsif is_chief_designer? || is_designer?
        query = "proyecto_areas.ingreso_diseno DESC"
      elsif is_chief_planning? || is_planner?
        query = "proyecto_areas.ingreso_planeamiento DESC"
      elsif is_costs?
        query = "proyecto_areas.ingreso_costos DESC"
      end
    
    elsif f == "Estado_Diseno"
      query = "proyecto_areas.estado_diseno ASC"
    
    elsif f == "Entrega_Diseno"
      query = "proyectos.fecha_entrega_diseno DESC"
    
    elsif f == "Entrega_Costos"
      query = "proyectos.fecha_entrega_costos DESC"
    
    elsif f == "Cierre"
      query = "opportunities.date_closed DESC"
    
    elsif f == "Entrega_ODT"
      query = "proyectos.fecha_de_entrega_odt DESC"
    
    elsif f == "Ejecutivo"
      query = "opportunities.assigned_user_id ASC"
    
    elsif f == "Dise&ntilde;ador"
      query = "proyecto_areas.encargado_diseno ASC"
    
    elsif f == "op_creado"
      query = "proyectos.fecha_creacion_proyecto DESC"
    
    elsif f == "op_recibido"
      query = "proyecto_areas.ingreso_operaciones DESC"
    
    else
      query = "DEFAULT"
    end
    
    set_order_field_for tab, f, query
    
    redirect_to :controller => "projects", :action => tab
  end
  
  
  def set_panel_page
    p = params[:page].to_i
    p = 1 if p <= 0
    
    session[:panel_page][params[:tab]] = p
    
    redirect_to :controller => "projects", :action => params[:tab]
  end
  
  
  def new
    @op = Opportunity.find params[:id]
    
    # Only one project can be associated to an Opportunity
    p = Proyecto.find_by_opportunity_id @op.id
    if p
      redirect_to(:action => "panel")
      return
    end
    
    @client = @op.accounts[0]
    
    # The client should have a RUC
    redirect_to(:action => "empty_ruc", :id => @op.id) unless @client.ruc
    
    @form = Fionna.new "new"
    
    # We fill here the Contacts select thingy
    account = Account.find @op.accounts[0].account_id
    
    contacts = OHash.new
    contacts["-1"] = "[Elija un contacto]"
    
    account.contacts.each do |c|
      contacts[c.contact_id] = c.full_name
    end
    
    @form.set_property_of :contacto, { "options" => contacts }
    
    if request.post?
      @form.load_values params
      
      if @form.canje == "1"
        @form.project_type = T_NUEVO_PROYECTO.to_s
      end
      
      if @form.project_type.to_i == T_NUEVO_PROYECTO
        @form.set_property_of :subtipo_nuevo_proyecto, "mandatory" => true
      else
        @form.subtipo_nuevo_proyecto = SUBTIPO_NUEVO_PROYECTO_MOBILIARIO
      end
      
      if @form.project_type.to_i == T_OTRO
        @form.set_property_of :other, "mandatory" => true
      end
      
      if [T_ORDEN_INTERNA, T_OTRO].include? @form.project_type.to_i
        @form.set_property_of :grio_password, "mandatory" => true
      end
      
      unless @form.fecha_entrega_diseno == ""
        @form.set_property_of :tipo_de_presentacion, "mandatory" => true
      end
      
      if @form.valid?
        fecha_diseno       = process_date "diseno"
        fecha_planeamiento = process_date "planeamiento"
        fecha_costos       = process_date "costos"
        
        data = @form.get_values
        
        set_default_values_for_a_new_project(data)
        
        if @form.orden_relacionada == ""
          orden_relacionada = nil
        else
          p = Proyecto.find_odt @form.orden_relacionada
          orden_relacionada = p.id
        end
        
        data[:contact_id]                 = @form.contacto
        data[:empresa_vendedora]          = @form.empresa_vendedora
        data[:tipo_de_venta]              = @form.tipo_de_venta
        data[:opportunity_id]             = @op.id
        data[:account_id]                 = @op.accounts[0].account_id
        data[:tipo_proyecto]              = @form.project_type
        data[:otro_tipo]                  = ""
        data[:fecha_entrega_diseno]       = fecha_diseno
        data[:fecha_entrega_planeamiento] = fecha_planeamiento
        data[:fecha_entrega_costos]       = fecha_costos
        data[:orden_relacionada]          = orden_relacionada
        
        data[:vista_frente]    = 1 if data["como_se_vera"].include? "FR"
        data[:vista_derecha]   = 1 if data["como_se_vera"].include? "DE"
        data[:vista_izquierda] = 1 if data["como_se_vera"].include? "IZ"
        data[:vista_atras]     = 1 if data["como_se_vera"].include? "AT"
        data[:vista_arriba]    = 1 if data["como_se_vera"].include? "AR"
        data[:vista_abajo]     = 1 if data["como_se_vera"].include? "AB"
        
        data[:monto_adelanto]          = 0.00
        data[:dias_plazo]              = nil
        data[:status_de_entrega_total] = 0
        data[:status_facturacion]      = F_POR_FACTURAR
        data[:status_cobranza]         = C_POR_COBRAR
        
        data[:cliente_razon_social]         = ''
        data[:cliente_ruc]                  = ''
        data[:cliente_direccion]            = ''
        data[:cliente_contacto]             = ''
        data[:cliente_telefono_fijo]        = ''
        data[:cliente_telefono_movil]       = ''
        data[:cliente_email]                = ''
        data[:factura_razon_social]         = ''
        data[:factura_ruc]                  = ''
        data[:factura_fecha_facturacion]    = nil
        data[:factura_descripcion]          = ''
        data[:factura_contraentrega]        = ''
        data[:factura_contacto_facturacion] = ''
        data[:factura_telefono_fijo]        = ''
        data[:factura_telefono_movil]       = ''
        data[:factura_email]                = ''
        data[:factura_direccion]            = ''
        data[:factura_observaciones]        = ''
        data[:factura_necesita_odt]         = '0'
        
        data.delete "contacto"
        data.delete "como_se_vera"
        data.delete "project_type"
        data.delete "other"
        data.delete "grio_password"
        ["diseno", "planeamiento", "costos"].each do |t|
          data.delete "fecha_entrega_" + t
          data.delete "hora_entrega_" + t
          data.delete "hora_am_pm_" + t
        end
        
        @p = Proyecto.new(data)
        
        if @p.save
          bootstrap_project(@p)
          
          redirect_to :action => "edit_fechas_de_entrega", :id => @p.uid
        end
      end
    end
  end
  
  
  def edit_details
    if request.post?
      approve_list = params[:ap]
      
      if approve_list
        @details = @project.detalles.each do |d|
          if approve_list.include? d.id.to_s
            d.aprobado = "1"
          else
            d.aprobado = "0"
          end
          
          d.save
        end
      end
      
      redirect_to :action => "show_details", :id => @project.uid, :type => @project.type
    end
  end
  
  
  def add_product
    @form = Fionna.new "add_product"
    
    @attributes = []
    
    if request.post?
      @form.load_values params
      
      attributes_are_ok = true
      
      unless @form.producto == "-1"
        @product    = Producto.find @form.producto
        
        # We create beforehand an object for each attribute and we put the
        # value that comes from POST
        # Later, if the Product is saved, we save all of these objects
        attributes = @product.atributos
        
        attributes.each_with_index do |a, i|
          p = params["attr" + i.to_s]
          if p.nil?
            v = ""
          else
            v = p
          end
          
          @attributes[i] = AtributosDetalle.new({
            :nombre      => a.nombre,
            :valor       => v,
            :tipo        => a.tipo,
            :orden       => a.orden
          })
          
          unless @attributes[i].valid?
            attributes_are_ok = false
          end
        end
      end
      
      if params[:button] && @form.valid? && attributes_are_ok
        # We add our new product to the details of our mighty project
        d = Detalle.new({
          :proyecto_id => @project.id,
          :descripcion => @form.descripcion,
          :cantidad    => @form.cantidad,
          :precio      => @form.precio,
          :producto_id => @product.id,
          :servicio_id => 0,
          :tipo        => "P",
          :aprobado    => "1",
          :marcados    => ""
        })
        
        d.save
        
        # We create and save its attributes
        @attributes.each do |a|
          a.detalle_id = d.id
          a.save
        end
        
        # We create the directory for this project
        unless File.exists?(d.path)
          FileUtils::mkdir d.path unless File.exists?(d.path)
        end
        
        # "Reset" the status of each area to make possible to work again on
        # a design or costs if you add or modify a design
        @project.reset_status(session[:user][:id])
        
        if params[:button] == "Guardar y agregar anexos"
          redirect_to :action => "show_detail", :id => @project.uid, :did => d.id, :type => @project.type
        else
          redirect_to :action => "edit_details", :id => @project.uid, :type => @project.type
        end
      end
    end
  end
  
  
  def add_service
    @form = Fionna.new "add_service"
    
    if request.post?
      @form.load_values params
      
      if params[:button] && @form.valid?
        # Agregamos el servicio al detalle
        d = Detalle.new({
          :proyecto_id   => @project.id,
          :descripcion   => @form.descripcion,
          :cantidad      => @form.cantidad,
          :precio        => @form.precio,
          :producto_id   => 0,
          :servicio_id   => @form.servicio,
          :tipo          => "S",
          :observaciones => @form.observaciones,
          :aprobado      => "1",
          :marcados      => ""
        })
        
        d.save
        
        
        # "Reset" the status of each area to make possible to work again on
        # a design or costs if you add or modify a design
        @project.reset_status(session[:user][:id])
        
        redirect_to :action => "edit_details", :id => @project.uid, :type => @project.type
      end
    end
  end
  
  
  def edit_detail
    @detail  = Detalle.find params[:did]
    
    unless @detail.proyecto_id == @project.id
      redirect_to :action => "edit_details", :id => @project.uid, :type => @project.type
    end
    
    if @detail.tipo == "P"
      edit_product
    else
      edit_service
    end
  end
  
 
  def edit_product
    @product = @detail.producto
    
    @form = Fionna.new "edit_product"
    
    @attributes = @detail.atributos_detalle
    
    if request.post?
      @form.load_values params
      
      attributes_are_ok = true
      
      @attributes.each do |a|
        p = params["attr" + a.id.to_s]
        if p.nil?
          v = ""
        else
          v = p
        end
        
        a.valor = v
        
        unless a.valid?
          attributes_are_ok = false
        end
      end
      
      if @form.valid? && attributes_are_ok
        # Update the attribs
        @attributes.each do |a|
          a.update
        end
        
        # If quantity has changed, we have to notify
        if (@detail.cantidad != @form.cantidad.to_i) && @project.con_orden_de_trabajo?
          notify = true 
        else
          notify = false
        end
        
        # Update the detail
        @detail.cantidad    = @form.cantidad
        @detail.descripcion = @form.descripcion
        @detail.precio      = @form.precio
        @detail.save
        
        Mail.product_qty_change_notification(session[:user][:id], @project.id) if notify
        
        # "Reset" the status of each area to work again on design or costs
        @project.reset_status(session[:user][:id])
        
        redirect_to :action => "edit_details", :id => @project.uid, :type => @project.type
      else
        render :action => "edit_product"
      end
    else
      values = {
        "descripcion" => @detail.descripcion,
        "cantidad"    => @detail.cantidad,
        "precio"      => (@detail.precio ? "%.2f" % @detail.precio : "0.00")
      }
      @form.load_values(values)
      
      render :action => "edit_product"
    end
  end
  
  
  def edit_service
    @service = @detail.servicio
    
    @form = Fionna.new "edit_service"
    
    if request.post?
      @form.load_values params
      
      if params[:button] && @form.valid?
        # If quantity has changed, we have to notify
        if @detail.cantidad != @form.cantidad.to_i
          notify = true 
        else
          notify = false
        end
        
        # Update the detail
        @detail.cantidad      = @form.cantidad
        @detail.servicio_id   = @form.servicio
        @detail.descripcion   = @form.descripcion
        @detail.observaciones = @form.observaciones
        @detail.precio        = @form.precio
        @detail.save
        
        Mail.product_qty_change_notification(session[:user][:id], @project.id) if notify
                
        # "Reset" blah blah
        @project.reset_status(session[:user][:id])
        
        redirect_to :action => "edit_details", :id => @project.uid, :type => @project.type
      else
        render :action => "edit_service"
      end
    else
      values = {
        "cantidad"      => @detail.cantidad,
        "categoria"     => @service.categoria_id,
        "servicio"      => @detail.servicio_id,
        "descripcion"   => @detail.descripcion,
        "observaciones" => @detail.observaciones,
        "precio"        => (@detail.precio ? "%.2f" % @detail.precio : "0.00")
      }
      @form.load_values(values)
      
      render :action => "edit_service"
    end
  end
  
  
  def delete_detail
    @detail  = Detalle.find(params[:did])
    
    # If it's a product, we must delete its directory
    if @detail.tipo == 'P'
      rmtree @detail.path if File.exists?(@detail.path)
    end
    
    Detalle.delete_all ["proyecto_id=? AND id=?", @project.id, params[:did]]
    
    redirect_to :action => "edit_details", :id => @project.uid, :type => @project.type
  end
  
  
  def show
    # Kinda hacky :(
    if is_facturation? && @project.con_orden_de_trabajo?
      redirect_to :controller => "facturation", :action => "order_facturation", :id => @project.orden_id
      return true
    end
    
    if @project.is_order?
      set_current_tab "orders"
    else
      set_current_tab "projects"
    end
    
    if is_operations_validator?
      @form = Fionna.new "show_operations_validation"
      
      if request.post?
        if params[:approve]
          @project.area.en_validacion_operaciones            = false
          @project.area.observaciones_validacion_operaciones = '';
          
          @project.area.en_operaciones      = true
          @project.area.ingreso_operaciones = Time.now
          @project.area.estado_operaciones  = E_OPERACIONES_EN_PROCESO
          @project.area.save
          
          if @project.subtipo_nuevo_proyecto_mobiliario?
            area = :operations_mob
          else
            area = :operations_arq
          end
          
          set_project_status E_OPERACIONES_EN_PROCESO
          Mail.sent_to_area(session[:user][:id], @project, area)
        else
          @form.load_values params
          
          if @form.valid?
            @project.area.en_validacion_operaciones            = false
            @project.area.observaciones_validacion_operaciones = @form.observaciones;
            @project.area.save
            
            Mail.operations_validator_disapproved(session[:user], @project, @form.observaciones)
            
            redirect_to :action => "show"
          end
        end
      end
    end
    
    if is_printviewer?
      @details = @project.detalles
      
      render :action => "show_printviewer"
    end
    
  end
  
  
  def show_details
    @details  = @project.detalles
  end
  
  
  def show_detail
    @detail  = Detalle.find(params[:did])
    
    unless @detail.proyecto_id == @project.id
      redirect_to :action => "show_details", :id => @project.uid, :type => @project.type
    end
    
    if @detail.tipo == "P"
      show_product
    else
      show_service
    end
  end
  
  
  def show_product
    @product    = @detail.producto
    @attributes = @detail.atributos_detalle
    
    if request.post?
      copy_data_file(params[:file], @detail.path) if params[:file]
      
      redirect_to :action => "show_detail", :id => @project.uid, :did => @detail.id, :type => @project.type
    else
      @project_files = @detail.get_project_files
      @product_files = @product.get_files
      render :action => "show_product"
    end
  end
  
  
  def show_service
    @service = @detail.servicio
    
    render :action => "show_service"
  end
  
  
  def edit_project
    @form = Fionna.new "edit_project"
    
    # We make mandatories the date of Entrega if the project is still not sent
    # to Operations
    if @project.area.ingreso_operaciones.nil?
      @entrega_editable = true
      
      @form.set_property_of "fecha_entrega_odt", { "mandatory" => true }
      @form.set_property_of "hora_entrega_odt",  { "mandatory" => true }
      @form.set_property_of "hora_am_pm_odt",    { "mandatory" => true }
    else
      @entrega_editable = false
    end
    
    # We fill here the Contacts select thingy
    account = Account.find @project.account_id
    
    contacts = OHash.new
    contacts["-1"] = "[Elija un contacto]"
    
    account.contacts.each do |c|
      contacts[c.contact_id] = c.full_name
    end
    
    @form.set_property_of :contacto, { "options" => contacts }
    
    if request.post?
      @form.load_values params
      
      unless @form.fecha_entrega_diseno == ""
        @form.set_property_of :tipo_de_presentacion, "mandatory" => true
      end
      
      if params["button"] && @form.valid?
        fecha_diseno       = process_date "diseno"
        fecha_planeamiento = process_date "planeamiento"
        fecha_costos       = process_date "costos"
        fecha_odt          = process_date "odt"
        
        data = @form.get_values
        
        data[:fecha_entrega_diseno]       = fecha_diseno
        data[:fecha_entrega_planeamiento] = fecha_planeamiento
        data[:fecha_entrega_costos]       = fecha_costos
        
        data[:fecha_de_entrega_odt]       = fecha_odt if @entrega_editable
        
        data[:contact_id]                 = @form.contacto
        
        yeah_that = {
          "FR" => :vista_frente,
          "DE" => :vista_derecha,
          "IZ" => :vista_izquierda,
          "AT" => :vista_atras,
          "AR" => :vista_arriba,
          "AB" => :vista_abajo
        }
        
        yeah_that.each do |y|
          if data["como_se_vera"].include? y[0]
            data[y[1]] = 1
          else
            data[y[1]] = 0
          end
        end
        
        data[:vista_abajo] = 0
        
        ["diseno", "planeamiento", "costos", "odt"].each do |t|
          data.delete "fecha_entrega_" + t
          data.delete "hora_entrega_" + t
          data.delete "hora_am_pm_" + t
        end
        data.delete "como_se_vera"
        
        data.delete "contacto"
        
        @project.update_attributes data
        @project.update
        
        # Mail notifications for urgency
        process_notification_for_urgency(@project)
        
        if @project.tipo_proyecto == T_ORDEN_INTERNA
          Mail.internal_order_notification(session[:user][:id], @project.id)
        end
        
        redirect_to_show_project
      end
    else
      values = @project.attributes
      
      ["diseno", "planeamiento", "costos"].each do |d|
        if @project.send("fecha_entrega_" + d).nil?
          values["fecha_entrega_" + d] = ""
          values["hora_entrega_" + d]  = ""
        else
          values["fecha_entrega_" + d] = @project.send("fecha_entrega_" + d).strftime "%d/%m/%y"
          values["hora_entrega_" + d]  = @project.send("fecha_entrega_" + d).strftime "%I%M"
          values["hora_am_pm_" + d]    = @project.send("fecha_entrega_" + d).strftime "%p"
        end
      end
      
      if @project.fecha_de_entrega_odt.nil?
        values["fecha_entrega_odt"]  = ''
        values["hora_entrega_odt"]   = ''
        values["hora_am_pm_odt"]     = ''
      else
        values["fecha_entrega_odt"] = @project.fecha_de_entrega_odt.strftime "%d/%m/%y"
        values["hora_entrega_odt"]  = @project.fecha_de_entrega_odt.strftime "%I%M"
        values["hora_am_pm_odt"]    = @project.fecha_de_entrega_odt.strftime "%p"
      end
      
      
      values["como_se_vera"] = []
      values["como_se_vera"] << "FR" if @project.vista_frente?
      values["como_se_vera"] << "DE" if @project.vista_derecha?
      values["como_se_vera"] << "IZ" if @project.vista_izquierda?
      values["como_se_vera"] << "AT" if @project.vista_atras?
      values["como_se_vera"] << "AR" if @project.vista_arriba?
      values["como_se_vera"] << "AB" if @project.vista_abajo?
      
      values["contacto"]     = @project.contact_id
      values["project_type"] = @project.tipo_proyecto
      
      @form.load_values values
    end
  end
  
  
  def send_to_area
    @area = @project.area
  end
  
  
  def send_to
    @area = @project.area
    aid   = params[:aid].to_i
    
    if params[:urgent] == "1"
      urgent = true
    else
      urgent = false
    end
    
    if params[:venta_asegurada] == "1"
      venta_asegurada = true
    else
      venta_asegurada = false
    end
    
    if aid == A_DISENO && @project.can_be_sent_to?(A_DISENO)
      @area.en_diseno      = true
      @area.ingreso_diseno = Time.now
      
      if @area.encargado_diseno.empty?
        status = E_DISENO_SIN_ASIGNAR
      else
        status = E_DISENO_EN_PROCESO
      end
      
      @area.estado_diseno = status
      @area.save
      
      set_project_status status
      
      Mail.sent_to_area(session[:user][:id], @project, aid)
      
      if urgent
        Mail.urgent_notification(session[:user][:id], @project.id, A_DISENO)
        @project.urgente_diseno = true
        @project.save
      end
      
    
    elsif aid == A_PLANEAMIENTO && @project.can_be_sent_to?(A_PLANEAMIENTO)
      @area.en_planeamiento      = true
      @area.ingreso_planeamiento = Time.now
      
      if @area.encargado_planeamiento.empty?
        status = E_PLANEAMIENTO_SIN_ASIGNAR
      else
        status = E_PLANEAMIENTO_EN_PROCESO
      end
      
      @area.estado_planeamiento = status
      @area.save
      
      set_project_status status
      
      Mail.sent_to_area(session[:user][:id], @project, aid)
      
      if urgent
        Mail.urgent_notification(session[:user][:id], @project.id, A_PLANEAMIENTO)
        @project.urgente_planeamiento = true
        @project.save
      end
    
    elsif aid == A_COSTOS && @project.can_be_sent_to?(A_COSTOS)
      @area.en_costos      = true
      @area.ingreso_costos = Time.now
      @area.estado_costos  = E_COSTOS_EN_PROCESO
      @area.save
      
      set_project_status E_COSTOS_EN_PROCESO
      
      Mail.sent_to_area(session[:user][:id], @project, aid)
      
      if urgent
        Mail.urgent_notification(session[:user][:id], @project.id, A_COSTOS)
        @project.urgente_costos = true
        @project.save
      end
    
    elsif aid == A_OPERACIONES && @project.can_be_sent_to?(A_OPERACIONES)
      # Here's a special case: the project is not directly sent to Operaciones
      # but has to be validated by the operations_validator user first.
      @area.en_validacion_operaciones = true
      @area.save
      
      if venta_asegurada
        @project.notificado_como_venta_asegurada = true
        @project.save
      end
    
    elsif aid == A_INNOVACIONES && @project.can_be_sent_to?(A_INNOVACIONES)
      @area.en_innovaciones      = true
      @area.ingreso_innovaciones = Time.now
      @area.estado_innovaciones  = E_INNOVACIONES_EN_PROCESO
      @area.save
      
      set_project_status E_INNOVACIONES_EN_PROCESO
      
      Mail.sent_to_area(session[:user][:id], @project, aid)
    
    elsif aid == A_INSTALACIONES && @project.can_be_sent_to?(A_INSTALACIONES)
      @area.en_instalaciones      = true
      @area.ingreso_instalaciones = Time.now
      @area.estado_instalaciones  = E_INSTALACIONES_EN_PROCESO
      @area.save
      
      set_project_status E_INSTALACIONES_EN_PROCESO
      
      Mail.sent_to_area(session[:user][:id], @project, aid)
    
    end
    
    redirect_to :action => "areas", :id => @project.uid, :type => @project.type
  end
  
  
  def assign_designer
    @designers = User.list_of :designers
    
    unless params[:uid].nil?
      @designer = User.find params[:uid]
      
      @project.area.encargado_diseno = @designer.id
      @project.area.update
      
      set_project_status E_DISENO_EN_PROCESO
      
      Mail.assign_designer(session[:user][:id], @project.id, @designer.id)
      
      redirect_to :action => "panel"
    end
  end
  
  
  def notify_design
    set_project_status E_DISENO_POR_APROBAR
    
    Mail.notification(session[:user][:id], @project.id, A_DISENO)
    
    redirect_to :action => "panel"
  end
  
  
  def notify_design_development
    @project.area.en_desarrollo      = true
    @project.area.ingreso_desarrollo = Time.now
    @project.save
    
    Mail.notification_of_design_to_devel(session[:user][:id], @project)
    
    redirect_to :action => "panel"
  end
  
  
  def design
    @messages = Mensaje.diseno @project.id
    
    @form = Fionna.new "mensajes"
    
    if request.post?
      if params[:ap]
        set_project_status E_DISENO_APROBADO
        @project.area.salida_diseno = Time.now
        @project.area.update
        Mail.notification_of_design_approved(session[:user][:id], @project.id)
      elsif params[:ob]
        set_project_status E_DISENO_OBSERVADO
        Mail.notification_of_observed(session[:user][:id], @project.id, A_DISENO)
      end
      
      redirect_to :action => "design", :id => @project.uid, :type => @project.type
    end
  end
  
  
  def design_development
    @messages = Mensaje.diseno_desarrollo @project.id
    @form     = Fionna.new "mensajes"
  end
  
  
  def planning
    @messages = Mensaje.planeamiento @project.id
    
    @form = Fionna.new "mensajes"
    
    if request.post?
      if params[:ap]
        set_project_status E_PLANEAMIENTO_TERMINADO
        @project.area.salida_planeamiento = Time.now
        @project.area.update
      elsif params[:ob]
        set_project_status E_PLANEAMIENTO_OBSERVADO
      end
      
      redirect_to :action => "planning", :id => @project.uid, :type => @project.type
    end
  end
  
  
  def costs
    @messages = Mensaje.costos @project.id
    @files    = @project.get_costs_files
    
    @form  = Fionna.new "costs"
    @form2 = Fionna.new "mensajes"
    
    if request.post? && (can_access?(:costs) || can_access?(:executive_tasks))
      if (params[:b] == "Guardar cambios") && costs_are_editable?
        @form.load_values params
        
        if @form.valid?
          @project.con_igv     = @form.con_igv
          @project.comision    = @form.comision
          @project.update
          
          if @form.moneda == "S"
            curr = CRM_CURRENCY_SOLES
          else
            curr = CRM_CURRENCY_DOLARES
          end
          
          @project.opportunity.amount      = @form.valor_costo
          @project.opportunity.currency_id = curr
          @project.opportunity.update
          
          redirect_to :action => "panel"
        end
      elsif params[:b] == "Transferir"
        copy_data_file(params[:file], @project.costs_path) if params[:file]
        redirect_to :action => "costs", :id => @project.uid, :type => @project.type
      end
    else
      if @project.opportunity.currency_id == CRM_CURRENCY_DOLARES
        moneda = "D"
      else
        moneda = "S"
      end
      
      @form.load_values({
        "valor_costo"  => "%.2f" % (@project.opportunity.amount || 0),
        "moneda"       => moneda,
        "con_igv"      => @project.con_igv,
        "comision"     => "%.2f" % (@project.comision || 0)
      })
    end
  end
  
  
  def innovations
    @messages = Mensaje.innovaciones @project.id
    @files    = @project.get_innovations_files
    
    @form2 = Fionna.new "mensajes"
    
    if request.post? && can_access?(:innovations)
      if params[:b] == "Transferir"
        copy_data_file(params[:file], @project.innovations_path) if params[:file]
        redirect_to :action => "innovations", :id => @project.uid, :type => @project.type
      end
    end
  end
  
  
  def installations
    @messages = Mensaje.instalaciones @project.id
    @files    = @project.get_installations_files
    
    @form     = Fionna.new "installations"
    @form2    = Fionna.new "mensajes"
    
    if request.post?
      if can_access?(:installations)
        if params[:b] == "Transferir"
          copy_data_file(params[:file], @project.installations_path) if params[:file]
          redirect_to :action => "installations", :id => @project.uid, :type => @project.type
        
        elsif params[:save] && is_installations?
          @form.load_values params
          
          all_ok = false
          
          if @form.valid?
            all_ok = true
            
            # Process dates
            inicio = process_date_and_time(@form, "visita_cliente_inicio")
            fin    = process_date_and_time(@form, "visita_cliente_fin")
            
            if fin < inicio
              all_ok      = false
              @date_error = 1
            end
          end
          
          if all_ok
            @project.instalaciones_fecha_visita_inicio = inicio
            @project.instalaciones_fecha_visita_fin    = fin
            @project.save
            
            redirect_to :action => "installations", :id => @project.id, :type => @project.type
          end
        elsif params[:finished] && is_executive?
          @project.set_status(E_INSTALACIONES_TERMINADO, session[:user][:id])
          
          redirect_to :action => "installations", :id => @project.id, :type => @project.type
        end
      end
    else # GET, baby
      load_date_and_time(@form, "visita_cliente_inicio", @project.instalaciones_fecha_visita_inicio)
      load_date_and_time(@form, "visita_cliente_fin", @project.instalaciones_fecha_visita_fin)
    end
  end
  
  
  def post_message
    aid = params[:aid].to_i
    
    if request.post?
      @form = Fionna.new "mensajes"
      
      @form.load_values params
      
      if @form.valid?
        m = Mensaje.new({
          :proyecto_id => @project.id,
          :area_id     => aid,
          :mensaje     => @form.mensaje,
          :user_id     => session[:user][:id],
          :fecha       => Time.now
        })
        
        m.save
        
        # Find out who the sender and recipient are
        # Most conversations are between the Executive and some Area (and
        # viceversa), except for Dise\F1o/Desarrollo which behaves differently
        if aid == A_DISENO_DESARROLLO
          sender = User.find(session[:user][:id])
          
          if is_designer? || is_chief_designer?
            recipients = User.list_of :chief_development
          else
            recipients = [User.find(@project.area.encargado_diseno)]
          end
        
        else
          # Ok, it's an Executive <-> XYZ conversation
          if session[:user][:id] == @project.executive.id
            sender = @project.executive
            
            # We group the users by area in an array
            if aid == A_DISENO
              recipients = [User.find(@project.area.encargado_diseno)]
            elsif aid == A_PLANEAMIENTO
              recipients = [User.find(@project.area.encargado_planeamiento)]
            elsif aid == A_COSTOS
              recipients = User.list_of :costs
            elsif aid == A_OPERACIONES
              if @project.subtipo_nuevo_proyecto_mobiliario?
                recipients = User.list_of :operations_mob
              else
                recipients = User.list_of :operations_arq
              end
            elsif aid == A_INNOVACIONES
              recipients = User.list_of :innovations
            elsif aid == A_INSTALACIONES
              recipients = User.notification_list_of "installations_observation"
            else
              raise "NO RECIPIENTS FOR MESSAGE"
            end
          else
            # No, it's the XYZ dude who is answering to the Executive
            sender     = User.find(session[:user][:id])
            recipients = [@project.executive]
          end
        end
        
        # Send it!
        Mail.message(@project, sender, recipients, @form.mensaje, aid)
      end
    end
    
    redirect_to :action => AREAS[aid][:action], :id => @project.uid, :type => @project.type
  end
  
  
  def areas
    @area = @project.area
  end
  
  
  def assign_planner
    @designers = User.list_of :planners
    
    unless params[:uid].nil?
      @planner = User.find params[:uid]
      
      @project.area.encargado_planeamiento = @planner.id
      @project.area.update
      
      set_project_status E_PLANEAMIENTO_EN_PROCESO
      
      Mail.assign_planner(session[:user][:id], @project.id, @planner.id)
      
      redirect_to :action => "panel"
    end
  end
  
  
  def notify_plan
    set_project_status E_PLANEAMIENTO_POR_APROBAR
    @project.area.salida_planeamiento = Time.now
    @project.area.update
    
    Mail.notification(session[:user][:id], @project.id, A_PLANEAMIENTO)
    
    redirect_to :action => "panel"
  end
  
  
  def notify_costs
    set_project_status E_COSTOS_TERMINADO
    @project.area.salida_costos = Time.now
    @project.area.update
    
    Mail.notification(session[:user][:id], @project.id, A_COSTOS)
    
    redirect_to :action => "panel"
  end
  
  
  def get_file
    @detail  = Detalle.find params[:did]
    fid      = params[:fid].gsub /\//, ''
    file     = @detail.path + "/" + fid
    filename = File.real_filename(fid)
    
    if params[:print] == "1"
      print_file = IMAGE_CACHE_PATH + "project-" + @project.id.to_s + "-" + @detail.id.to_s + "-" + fid
      
      if File.exists?(file)
        unless File.exists?(print_file)
          width = `identify -format %w "#{file}"`.strip.to_i
          
          if width > IMAGE_PRINT_WIDTH
            `convert -geometry #{IMAGE_PRINT_WIDTH} "#{file}" "#{print_file}"`
          else
            FileUtils.copy file, print_file
          end
        end
      end
      
      file = print_file
    end
    
    if File.exists?(file)
      send_data(File.read(file),
        :filename    => filename,
        :type        => "application/octet-stream",
        :disposition => "attachment; filename=" + filename)
    end
  end
  
  
  def get_costs_file
    send_data_file_to_browser(@project.costs_path, params[:fid])
  end
  
  def get_innovations_file
    send_data_file_to_browser(@project.innovations_path, params[:fid])
  end
  
  
  def get_installations_file
    send_data_file_to_browser(@project.installations_path, params[:fid])
  end
  
  
  def cotization
    @cotizaciones = @project.cotizaciones
    @form         = Fionna.new "cotization"
    
    if request.post? && @project.can_create_cotizations?
      @form.load_values params
      
      # Let's see if there's details... hmmm...
      if params[:detalles] != nil && params[:detalles].class.to_s == "HashWithIndifferentAccess" && params[:detalles].size > 0
        detalles = params[:detalles]
      else
        detalles = HashWithIndifferentAccess.new
      end
      
      if params[:cantidad] != nil && params[:cantidad].class.to_s == "HashWithIndifferentAccess" && params[:cantidad].size > 0
        cantidad = params[:cantidad]
      else
        cantidad = HashWithIndifferentAccess.new
      end
      
      if params[:precio] != nil && params[:precio].class.to_s == "HashWithIndifferentAccess" && params[:precio].size > 0
        precio = params[:precio]
      else
        precio = HashWithIndifferentAccess.new
      end
      
      # We build the Fionna objects for each detail
      if @form.especificar_detalles == "1" && detalles.size > 0
        @detalles = Array.new
        
        # We prepare the list of deleted ones, if there really are
        if params[:delete] && params[:delete].class.to_s == "HashWithIndifferentAccess"
          delete_list = params[:delete].keys
        else
          delete_list = Array.new
        end
        
        0.upto(detalles.size - 1) do |i|
          i = i.to_s
          
          unless delete_list.include? i
            t = Fionna.new "cotizacion_detalle"
            
            unless detalles[i].nil?
              t.detalles = detalles[i]
              t.cantidad = cantidad[i]
              t.precio   = precio[i]
            end
            
            @detalles << t
          end
        end
      else
        @detalles = Array.new
        @detalles[0] = Fionna.new "cotizacion_detalle"
      end
      
      # Has he asked for another field?
      unless params[:more].nil?
        @detalles << Fionna.new("cotizacion_detalle")
      end
      
      # If he has pressed the button to generate the cotization, we first
      # verify if all details are valid
      details_looks_fine = true
      
      if params[:ok] && @form.especificar_detalles == "1"
        @detalles.each_with_index do |d, i|
          unless @detalles[i].valid?
            details_looks_fine = false
          end
        end
      end
      
      # Same thing with the cotization
      if params[:ok] && @form.valid?
        coti_looks_fine = true
      else
        coti_looks_fine = false
      end
      
      
      if details_looks_fine && coti_looks_fine
        c = Cotizacion.new({
          :proyecto_id          => @project.id,
          :codigo               => "",
          :version              => @cotizaciones.size,
          :tiempo_de_entrega    => @form.tiempo_de_entrega,
          :forma_de_pago        => @form.forma_de_pago,
          :moneda               => @form.moneda,
          :contacto             => @form.contacto,
          :validez_de_oferta    => @form.validez_de_oferta,
          :notas                => @form.notas,
          :incluir_gran_total   => @form.incluir_gran_total,
          :especificar_detalles => @form.especificar_detalles
        })
        
        c.save
        
        if c.version == 0
          c.codigo = Time.now.strftime("P%y%m") + c.id.to_s.rjust(5, '0')
        else
          c.codigo = @cotizaciones[0].codigo + "-" + c.version.to_s
        end
        
        c.update
        
        # The newly created Cotization will be the one marked
        Cotizacion.mark c.id
        
        # If details were specified by hand, we save them
        if @form.especificar_detalles == "1"
          @detalles.each do |d|
            dd = CotizacionDetalle.new({
              :cotizacion_id => c.id,
              :nombre        => d.detalles,
              :cantidad      => d.cantidad,
              :producto_id   => nil,
              :servicio_id   => nil,
              :tipo          => "M",
              :precio        => d.precio,
              :descripcion   => ""
            })
            
            dd.save
          end
        else
          # else, we save the details that belong to the project
          @project.detalles.each do |d|
            if d.tipo == "P"
              nombre = d.producto.nombre
            elsif d.tipo == "S"
              nombre = d.servicio.nombre
            end
            
            dd = CotizacionDetalle.new({
              :cotizacion_id => c.id,
              :nombre        => nombre,
              :cantidad      => d.cantidad,
              :producto_id   => d.producto_id,
              :servicio_id   => d.servicio_id,
              :tipo          => d.tipo,
              :precio        => d.precio,
              :descripcion   => d.descripcion
            })
            
            dd.save
          end
        end
        
        @project.tiene_cotizaciones = true
        @project.save
        
        redirect_to :action => "cotization", :id => @project.id
      end
    else
      # GET request
      
      if params[:cid]
        @c = Cotizacion.find params[:cid]
        
        if @c
          @form.load_values({
            "tiempo_de_entrega"    => @c.tiempo_de_entrega,
            "forma_de_pago"        => @c.forma_de_pago,
            "moneda"               => @c.moneda,
            "contacto"             => @c.contacto,
            "validez_de_oferta"    => @c.validez_de_oferta,
            "notas"                => @c.notas,
            "incluir_gran_total"   => (@c.incluir_gran_total? ? "1" : nil),
            "especificar_detalles" => (@c.especificar_detalles? ? "1" : nil)
          })
          
          # If there are details, we load them
          if @c.especificar_detalles?
            @detalles = Array.new
            
            detalles = CotizacionDetalle.find_all_by_cotizacion_id @c.id, :order => "id"
            
            detalles.each do |d|
              f = Fionna.new "cotizacion_detalle"
              f.load_values({
                "detalles" => d.nombre,
                "cantidad" => d.cantidad,
                "precio"   => d.precio
              })
              
              @detalles << f
            end
          else
            @detalles = Array.new
            @detalles[0] = Fionna.new "cotizacion_detalle"
          end
        end
      else
        @detalles = Array.new
        @detalles[0] = Fionna.new "cotizacion_detalle"
      end
    end
  end
  
  
  def view_cotizacion
    @cotizacion = Cotizacion.find params[:cid]
    
    if @cotizacion.proyecto_id != @project.id
      redirect_to :action => "panel"
    end
    
    # Are there details?
    @details = @cotizacion.details
    
    if params[:save].nil?
      @full_url_link_for_header = false
    else
      # It's trying to save the page
      @full_url_link_for_header = true
    end
    
    render :layout => false
  end
  
  
  def email_cotizacion
    @cotizacion = Cotizacion.find params[:cid]
    
    # Are there details?
    @details = @cotizacion.details
    
    @full_url_link_for_header = true
    
    # We get the exec to be its "sender"
    @exec = @project.executive
    
    if @cotizacion.proyecto_id != @project.id
      redirect_to :action => "panel"
    end
    
    @form = Fionna.new "email_cotizacion"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        html = render_to_string :action => "view_cotizacion", :layout => false
        
        if @form.email.include? ","
          emails = @form.email.split ","
        else
          emails = @form.email
        end
        
        Mail.cotizacion @exec, @form.email, @cotizacion.codigo, html
        
        redirect_to :action => "cotizacion_sent", :id => @project.id
      end
    end
  end
  
  
  def cotizacion_sent
  end
  
  
  def edit_metadata
    @form = Fionna.new "edit_metadata"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        @project.opportunity.assigned_user_id = @form.ejecutivo
        
        @project.opportunity.update
        
        # Update the dates according to the current status
        unless @project.area.en_diseno == @form.enviado_diseno
          if @form.enviado_diseno == "1"
            ingreso_diseno = Time.now
            salida_diseno  = nil
          else
            ingreso_diseno = nil
            salida_diseno  = nil
          end
        else
          ingreso_diseno = @project.area.ingreso_diseno
          salida_diseno  = @project.area.salida_diseno
        end
        
        unless @project.area.en_planeamiento == @form.enviado_planeamiento
          if @form.enviado_planeamiento == "1"
            ingreso_planeamiento = Time.now
            salida_planeamiento  = nil
          else
            ingreso_planeamiento = nil
            salida_planeamiento  = nil
          end
        else
          ingreso_planeamiento = @project.area.ingreso_planeamiento
          salida_planeamiento  = @project.area.salida_planeamiento
        end
        
        unless @project.area.en_costos == @form.enviado_costos
          if @form.enviado_costos == "1"
            ingreso_costos = Time.now
            salida_costos  = nil
          else
            ingreso_costos = nil
            salida_costos  = nil
          end
        else
          ingreso_costos = @project.area.ingreso_costos
          salida_costos  = @project.area.salida_costos
        end
        
        @project.area.update_attributes({
          :en_diseno            => @form.enviado_diseno,
          :estado_diseno        => @form.estado_diseno,
          :ingreso_diseno       => ingreso_diseno,
          :salida_diseno        => salida_diseno,
          
          :en_planeamiento      => @form.enviado_planeamiento,
          :estado_planeamiento  => @form.estado_planeamiento,
          :ingreso_planeamiento => ingreso_planeamiento,
          :salida_planeamiento  => salida_planeamiento,
          
          :en_costos            => @form.enviado_costos,
          :estado_costos        => @form.estado_costos,
          :ingreso_costos       => ingreso_costos,
          :salida_costos        => salida_costos
        })
        
        @project.area.update
        
        redirect_to_show_project
      end
    else
      if @project.opportunity.sales_stage == "Closed Won"
        estado = "1"
      elsif @project.opportunity.sales_stage == "Closed Lost"
        estado = "2"
      else
        estado = "0"
      end
      
      @form.load_values({
        "ejecutivo"            => @project.opportunity.assigned_user_id,
        "estado_proyecto"      => estado,
        "enviado_diseno"       => (@project.area.en_diseno? ? true : nil),
        "estado_diseno"        => @project.area.estado_diseno,
        
        "enviado_planeamiento" => (@project.area.en_planeamiento? ? true : nil),
        "estado_planeamiento"  => @project.area.estado_planeamiento,
        
        "enviado_costos"       => (@project.area.en_costos? ? true : nil),
        "estado_costos"        => @project.area.estado_costos,
      })
    end
  end
  
  
  def delete_project_file
    @detail  = Detalle.find(params[:did])
    fid      = params[:fid].gsub /\//, ''
    file     = @detail.path + fid
    
    File.delete(file) if File.exists?(file)
    
    redirect_to :action => "show_detail", :id => @project.uid, :did => params[:did], :type => @project.type
  end
  
  
  def archive
    @form = Fionna.new "archive"
    
    @panel_fields = PANEL_ARCHIVE
    sql = "SELECT proyectos.*
             FROM proyectos,
                  opportunities,
                  proyecto_areas
            WHERE proyecto_areas.proyecto_id=proyectos.id
              AND opportunities.id=proyectos.opportunity_id
              AND NOT(#{SQL_VERA_DELETED}) "
    
    if is_executive?
      extra_sql = "AND opportunities.assigned_user_id='#{session[:user][:id]}'"
      
      if is_supervisor?
        if params[:q]
          @form.load_values params
          
          if @form.valid?
            if @form.executive == "-1"
              extra_sql = ""
            else
              extra_sql = "AND opportunities.assigned_user_id='#{session[:user][:id]}'"
            end
          end
        else
          extra_sql = ""
        end
      end
      
      sql   = sql + extra_sql
      order = "fecha_creacion_proyecto DESC"
    
    elsif is_chief_designer?
      sql   = sql + "AND proyecto_areas.en_diseno='1' AND proyecto_areas.estado_diseno='" + E_DISENO_APROBADO.to_s + "'"
      order = "fecha_creacion_proyecto DESC"
    
    elsif is_designer?
      sql   = sql + "AND proyecto_areas.en_diseno='1' AND proyecto_areas.estado_diseno='" + E_DISENO_APROBADO.to_s + "' AND proyecto_areas.encargado_diseno='#{session[:user][:id]}'"
      order = "fecha_creacion_proyecto DESC"
    
    elsif is_chief_planning?
      sql   = sql + "AND proyecto_areas.en_planeamiento='1' AND proyecto_areas.estado_planeamiento='" + E_PLANEAMIENTO_TERMINADO.to_s + "'"
      order = "fecha_creacion_proyecto DESC"
    
    elsif is_planner?
      sql   = sql + "AND proyecto_areas.en_planeamiento='1' AND proyecto_areas.estado_planeamiento='" + E_PLANEAMIENTO_TERMINADO.to_s + "' AND proyecto_areas.encargado_planeamiento='#{session[:user][:id]}'"
      order = "fecha_creacion_proyecto DESC"
    
    elsif is_costs?
      sql   = sql + "AND proyecto_areas.en_costos='1' AND proyecto_areas.estado_costos='" + E_COSTOS_TERMINADO.to_s + "'"
      order = "fecha_creacion_proyecto DESC"
    
    elsif is_operations?
      sql   = sql + "AND proyecto_areas.en_operaciones='1' AND proyecto_areas.estado_operaciones='" + E_OPERACIONES_TERMINADO.to_s + "'"
      order = "fecha_creacion_proyecto DESC"
    
    else
      redirect_to :controller => "users", :action => "login"
    end
    
    sql = sql + " ORDER BY " + order
    
    @projects = Proyecto.find_by_sql sql
  end
  
  
  def archive_orders
    @form = Fionna.new "archive"
    
    @panel_fields = PANEL_ARCHIVE_ORDERS
    
    conditions = "proyectos.con_orden_de_trabajo=1 AND (proyectos.postvendido='1' OR proyectos.anulado='1' OR proyectos.autorizado_para_facturar='1') "
    
    extra_sql = "AND opportunities.assigned_user_id='#{session[:user][:id]}'"
    
    if is_supervisor?
      if params[:q]
        @form.load_values params
        
        if @form.valid?
          if @form.executive == "-1"
            extra_sql = ""
          else
            extra_sql = "AND opportunities.assigned_user_id='#{@form.executive}'"
          end
        end
      else
        extra_sql = ""
      end
    end
    
    conditions = conditions + extra_sql
    
    @projects = Proyecto.find :all, :include => [:opportunity], :conditions => conditions, :order => "orden_id DESC"
  end
  
  
  def mark_cotization
    Cotizacion.mark params[:cid].to_i
    render :nothing => true
  end
  
  
  def promote
  # Both promotes to Order and edits the confirmation data
    if @project.estado_validacion == E_VALIDACION_POR_APROBAR
      redirect_to :action => "confirmation_data_of_order", :id => @project.uid, :type => @project.type
      return true
    end
    
    @opportunity      = @project.opportunity
    @form_cliente     = Fionna.new "promote_cliente"
    @form_facturar    = Fionna.new "promote_facturar"
    @form_operaciones = Fionna.new "promote_operaciones"
    
    ignore_cliente     = false
    ignore_facturar    = false
    ignore_operaciones = false
    
    # Are we gonna promote this for the first time, as in create an ODT?
    # Then, we check if this Account is blocked, cos' baby, you can't do
    # that...
    if @project.con_orden_de_trabajo? == false && @project.account.blocked? && !params[:pre_editing]
      redirect_to :action => "account_blocked", :id => @project.id
    end
    
    # What are we doing?
    if params[:pre_editing]
      # Preediting, that is, editing the data when it's still a Project
      @preediting = true
      @editing    = false
      @promoting  = false
    else
      if @project.con_orden_de_trabajo?
        # Editing, this is an existing ODT
        @preediting = false
        @editing    = true
        @promoting  = false
      else
        # Promoting, this is a Project on its way to be promoted
        @preediting = false
        @editing    = false
        @promoting  = true
      end
    end
    
    # If it's not a new project, then some sections are ignored
    unless @project.tipo_nuevo_proyecto?
      ignore_facturar = true
      ignore_cliente  = true
    end
    
    # If we are pre-editing, then we set as non-mandatory several fields
    if @preediting
      ["cliente_razon_social", "cliente_ruc", "cliente_direccion", "cliente_contacto", "cliente_telefono_fijo", "cliente_telefono_movil", "cliente_email"].each do |f|
        @form_cliente.set_property_of f, { "mandatory" => false }
      end
      
      ["monto_de_venta", "motivo_monto", "moneda", "incluye_igv", "clave_modificacion_monto", "factura_necesita_odt", "factura_cliente", "factura_direccion_fiscal", "factura_fecha_facturacion", "factura_hora_facturacion", "hora_am_pm_f", "factura_descripcion", "factura_con_adelanto", "factura_tipo_adelanto", "factura_porcentaje", "monto_adelanto", "factura_contraentrega", "dias_plazo", "factura_contacto_facturacion", "factura_telefono_fijo", "factura_telefono_movil", "factura_email", "factura_direccion", "factura_observaciones", "autorizacion"].each do |f|
        @form_facturar.set_property_of f, { "mandatory" => false }
      end
      
      ["se_necesita_supervisor"].each do |f|
        @form_operaciones.set_property_of f, { "mandatory" => false }
      end
    end
    
    # Special case
    if !@project.tipo_nuevo_proyecto? || @project.has_facturas_or_boletas?
      @form_facturar.set_property_of "monto_de_venta", { "mandatory" => false }
      @form_facturar.set_property_of "moneda", { "mandatory" => false }
      @form_facturar.moneda = "S"
    end
    
    if request.post?
      @form_cliente.load_values params
      @form_facturar.load_values params
      @form_operaciones.load_values params
      
      @form_facturar.empresa    = @project.empresa_vendedora.to_s
      @form_operaciones.empresa = @project.empresa_vendedora.to_s
      
      # Validation for section Cliente
      if params[:ok] && @form_cliente.valid?
        cliente_valid = true
      end
      
      # Validation for section Facturar
      
      # The ajaxy Factura Account thing special case
      if params[:account] && params[:account][:name]
        @form_facturar.factura_cliente = params[:account][:name]
      end
      
      if @preediting
        confirmation_docs_ok = true
        costs_docs_ok        = true
      else
        # Documents party
        if @project.tipo_nuevo_proyecto?
          if @project.has_confirmation_docs?
            confirmation_docs_ok = true
          else
            confirmation_docs_ok = false
            @show_confirmation_docs_error_message = true
          end
          
          if @project.has_costs_files?
            costs_docs_ok = true
          else
            costs_docs_ok = false
            @show_costs_docs_error_message = true
          end
        else
          confirmation_docs_ok = true
          costs_docs_ok        = true
        end
        
        # Authorize thing for Consorcio
        if @project.empresa_vendedora == CONSORCIO && @editing == false
          @form_facturar.set_property_of :autorizacion, { "mandatory" => true }
        end
      end

      if @form_facturar.factura_con_adelanto == "1"
        @form_facturar.set_property_of "factura_tipo_adelanto", { "mandatory" => true }
      else
        @form_facturar.factura_tipo_adelanto = ''
        @form_facturar.factura_porcentaje    = ''
        @form_facturar.monto_adelanto        = ''
      end
      
      if @form_facturar.factura_tipo_adelanto == "P"
        @form_facturar.set_property_of "factura_porcentaje", { "mandatory" => true }
      elsif @form_facturar.factura_tipo_adelanto == "M"
        @form_facturar.set_property_of "monto_adelanto", { "mandatory" => true }
      end
      
      if @form_facturar.factura_contraentrega == "0"
        @form_facturar.set_property_of "dias_plazo", { "mandatory" => true }
      else
        @form_facturar.dias_plazo = ''
      end
      
      if @project.has_facturas_or_boletas?
        # We leave its values unchanged
        monto_odt       = @project.monto_odt
        incluye_igv_odt = @project.incluye_igv_odt
        moneda_odt      = @project.moneda_odt
        
        @form_facturar.monto_adelanto        = @project.monto_adelanto.to_s
        @form_facturar.factura_contraentrega = @project.factura_contraentrega
        @form_facturar.dias_plazo            = @project.dias_plazo.to_s
      else
        monto_odt       = @form_facturar.monto_de_venta
        incluye_igv_odt = @form_facturar.incluye_igv
        moneda_odt      = @form_facturar.moneda
      end
      
#      if @project.has_facturas? || @preediting
#        [:monto_de_venta, :incluye_igv, :moneda, :factura_contraentrega].each do |p|
#          @form_facturar.set_property_of p, { "mandatory" => false }
#        end
#      end
      
      # Now, we check if they tried to change the Price
      notify_change = false
      
      # Fields that only apply when editing a New Project type
      if @editing && @project.tipo_nuevo_proyecto?
        # If he really tried to change the price, he must have wrote a
        # motive, so we activate that here
        if !@project.has_facturas_or_boletas? && (@opportunity.amount != @form_facturar.monto_de_venta.to_f ||
           @project.incluye_igv_odt != @form_facturar.incluye_igv ||
           @project.moneda_odt != @form_facturar.moneda)
          @form_facturar.set_property_of :motivo_monto, { "mandatory" => true }
          @form_facturar.set_property_of :clave_modificacion_monto, { "mandatory" => true }
          
          old_price = verbose_odt_price(@project)
          
          # We don't want to double check later, so we find here if he really
          # wrote a motive. If he didn't, the validation will fail and the
          # error message will be printed later
          if @form_facturar.motivo_monto != ""
            notify_change = true
          end
        end
      end
      
      # Direcci\F3n Fiscal
      unless @form_facturar.factura_cliente == ""
        acct = Account.search(@form_facturar.factura_cliente)
        
        if acct && acct.extras.factura_direccion_fiscal.nil?
          @edit_direccion_fiscal = true
        else
          @edit_direccion_fiscal = false
        end
      end
      
      if @edit_direccion_fiscal
        @form_facturar.set_property_of :factura_direccion_fiscal, { "mandatory" => true }
      end
      
      # Monto de Adelanto
      if @form_facturar.factura_tipo_adelanto == 'M'
        if @form_facturar.monto_adelanto.to_f > @project.opportunity.amount
          @form_facturar.set_error_msg_of :monto_adelanto, "El monto de adelanto no puede ser mayor al Monto de Venta"
          price_ok = false
        else
          price_ok = true
        end
      else
        price_ok = true
      end
      
      if params[:ok] && @form_facturar.valid? && confirmation_docs_ok && costs_docs_ok && price_ok
        facturar_valid = true
      end
      
      
      # Validation for section Operaciones
      
      # Let's see if there's puntos de entrega
      if params[:punto] != nil && params[:punto].class.to_s == "HashWithIndifferentAccess" && params[:punto].size > 0
        punto = params[:punto]
      else
        punto = HashWithIndifferentAccess.new
      end
      
      if params[:contacto] != nil && params[:contacto].class.to_s == "HashWithIndifferentAccess" && params[:contacto].size > 0
        contacto = params[:contacto]
      else
        contacto = HashWithIndifferentAccess.new
      end
      
      if params[:telefono] != nil && params[:telefono].class.to_s == "HashWithIndifferentAccess" && params[:telefono].size > 0
        telefono = params[:telefono]
      else
        telefono = HashWithIndifferentAccess.new
      end
      
      if params[:hora] != nil && params[:hora].class.to_s == "HashWithIndifferentAccess" && params[:hora].size > 0
        hora = params[:hora]
      else
        hora = HashWithIndifferentAccess.new
      end
      
      # We build the Fionna objects for each punto
      if punto.size > 0
        @puntos = Array.new
        
        # We prepare the list of deleted ones, if there really are
        if params[:delete] && params[:delete].class.to_s == "HashWithIndifferentAccess"
          delete_list = params[:delete].keys
        else
          delete_list = Array.new
        end
        
        0.upto(punto.size - 1) do |i|
          i = i.to_s
          
          unless delete_list.include? i
            t = Fionna.new "promote_punto"
            
            unless punto[i].nil?
              t.punto    = punto[i]
              t.contacto = contacto[i]
              t.telefono = telefono[i]
              t.hora     = hora[i]
            end
            
            @puntos << t
          end
        end
      else
        @puntos = Array.new
        @puntos[0] = Fionna.new "promote_punto"
      end
      
      # Has he asked for another field?
      unless params[:more].nil?
        @puntos << Fionna.new("promote_punto")
      end
      
      # If he has pressed the button to save, we first
      # verify if all details are valid
      puntos_looks_fine = true
      
      if params[:ok]
        @puntos.each_with_index do |d, i|
          unless @puntos[i].valid?
            puntos_looks_fine = false
          end
        end
      end
      
      # Checkboxes check (heh)
      checkboxes_ok = true
      
      if params[:ok]
        unless @preediting
          if @form_operaciones.solo_entrega == "0" && 
             @form_operaciones.con_instalacion == "0" &&
             @form_operaciones.recojo_de_producto == "0"
            checkboxes_ok = false
            
            @error_msg_for_checkboxes = "Debes marcar al menos una opci&oacute;n de entrega o instalaci&oacute;n"
          end
        end
        
        if @form_operaciones.solo_entrega == "1" && 
           @form_operaciones.con_instalacion == "1"
          checkboxes_ok = false
          
          @error_msg_for_checkboxes = "No puedes marcar \"Solo Entrega\" y \"Con Instalaci&oacute;n\" a la vez"
        end
      end
      
      # Fecha de Desmontaje can't be earlier than Fecha de Creaci\F3n
      fecha_ok = true
      
      if @form_operaciones.valid?
        fecha_de_desmontaje = process_date_and_hour_2(@form_operaciones.fecha_de_desmontaje, @form_operaciones.hora_de_desmontaje, @form_operaciones.hora_am_pm_d)
        
        if params[:ok] && fecha_de_desmontaje != nil && fecha_de_desmontaje < @project.fecha_creacion_proyecto
          @form_operaciones.set_error_msg_of :fecha_de_desmontaje, "La fecha no puede ser antes que la fecha de creaci&oacute;n del Proyecto"
          fecha_ok = false
        end
      end
      
      if params[:ok] && @form_operaciones.valid? && puntos_looks_fine && fecha_ok && checkboxes_ok
        operaciones_valid = true
      end
      
      cliente_valid = true  if ignore_cliente == true
      facturar_valid = true if ignore_facturar == true
      
      # If project is incomplete, allow the saving of data
      # If project is already complete, only allow if all sections are valid
      if (@project.con_datos_pendientes_promote? == true) || (@project.con_datos_pendientes_promote? == false && cliente_valid && facturar_valid && operaciones_valid)
      
        if (cliente_valid == true) && (ignore_cliente == false)
          @project.update_attributes({
            :promote_data_edited           => true,
            
            :cliente_razon_social          => @form_cliente.cliente_razon_social,
            :cliente_ruc                   => @form_cliente.cliente_ruc,
            :cliente_direccion             => @form_cliente.cliente_direccion,
            :cliente_contacto              => @form_cliente.cliente_contacto,
            :cliente_telefono_fijo         => @form_cliente.cliente_telefono_fijo,
            :cliente_telefono_movil        => @form_cliente.cliente_telefono_movil,
            :cliente_email                 => @form_cliente.cliente_email,
          })
          
          @project.save
        end
        
        
        if (facturar_valid == true) && (ignore_facturar == false)
          if @form_facturar.factura_tipo_adelanto == 'P'
            # Let's calculate the amount here. We don't deal with percentages.
            @form_facturar.monto_adelanto = (@form_facturar.monto_de_venta.to_f * @form_facturar.factura_porcentaje.to_f) / 100
          end
          
          if @form_facturar.dias_plazo == ''
            @form_facturar.dias_plazo = "0"
          end
          
          fecha_facturacion = process_date_and_hour_2(@form_facturar.factura_fecha_facturacion, @form_facturar.factura_hora_facturacion, @form_facturar.hora_am_pm_f)
          
          if acct
            factura_account_id = acct.id
          else
            factura_account_id = ""
          end
          
          if @edit_direccion_fiscal
            acct.extras.factura_direccion_fiscal = @form_facturar.factura_direccion_fiscal
            acct.extras.save
          end
          
          # Melissa asked if there's an Adelanto, we mark it to be invoiced
          # automagically
          if @form_facturar.monto_adelanto != "" && !@preediting && @project.autorizado_para_facturar? == false
            @project.autorizado_para_facturar = true
            @project.save
            
            # Notify that
            Mail.odt_invoice(session[:user][:id], @project.id)
          end
          
          @project.update_attributes({
            :promote_data_edited           => true,
            
            :factura_necesita_odt          => @form_facturar.factura_necesita_odt,
            :factura_account_id            => factura_account_id,
            :factura_direccion_fiscal      => @form_facturar.factura_direccion_fiscal,
            :factura_fecha_facturacion     => fecha_facturacion,
            :factura_descripcion           => @form_facturar.factura_descripcion,
            :monto_adelanto                => @form_facturar.monto_adelanto,
            :factura_contraentrega         => @form_facturar.factura_contraentrega,
            :dias_plazo                    => @form_facturar.dias_plazo,
            :factura_contacto_facturacion  => @form_facturar.factura_contacto_facturacion,
            :factura_telefono_fijo         => @form_facturar.factura_telefono_fijo,
            :factura_telefono_movil        => @form_facturar.factura_telefono_movil,
            :factura_email                 => @form_facturar.factura_email,
            :factura_direccion             => @form_facturar.factura_direccion,
            :factura_observaciones         => @form_facturar.factura_observaciones,
            :monto_odt                     => monto_odt,
            :incluye_igv_odt               => incluye_igv_odt,
            :moneda_odt                    => moneda_odt
          })
          @project.save
          
          if @project.account.extras.new_record?
            e                   = @project.account.extras
            e.dias_plazo        = @form_facturar.dias_plazo
            e.factura_direccion = @form_facturar.factura_direccion
            e.save
          end
          
          new_price = verbose_odt_price(@project)
          
          if notify_change
            if @project.con_guias_completas?
              Mail.order_amount_change_notification_with_last_guia(session[:user][:id], @project.id, @form_facturar.motivo_monto, old_price, new_price)
            else
              Mail.order_amount_change_notification(session[:user][:id], @project.id, @form_facturar.motivo_monto, old_price, new_price)
            end
          end
        end
        
        
        if (operaciones_valid == true)
          @project.update_attributes({
            :promote_data_edited           => true,
            
            :solo_entrega                  => @form_operaciones.solo_entrega,
            :con_instalacion               => @form_operaciones.con_instalacion,
            :se_necesita_supervisor        => @form_operaciones.se_necesita_supervisor,
            :recojo_de_producto            => @form_operaciones.recojo_de_producto,
            :observaciones                 => @form_operaciones.observaciones,
            :fecha_de_desmontaje           => fecha_de_desmontaje,
            :colores_aprobados             => @form_operaciones.colores_aprobados,
            :igual_al_codigo_pantones      => @form_operaciones.igual_al_codigo_pantones,
            :presentar_muestra_de_color    => @form_operaciones.presentar_muestra_de_color,
            :graf_igual_a_muestra          => @form_operaciones.graf_igual_a_muestra,
            :graf_igual_a_pantones         => @form_operaciones.graf_igual_a_pantones,
            :graf_presentar_muestra        => @form_operaciones.graf_presentar_muestra,
            :confirmar_medidas             => @form_operaciones.confirmar_medidas,
          })
          @project.save
          
          PuntosDeEntrega.destroy_all ["proyecto_id=?", @project.id]
          
          @puntos.each do |d|
            p = PuntosDeEntrega.new({
              :proyecto_id => @project.id,
              :punto       => d.punto,
              :contacto    => d.contacto,
              :telefono    => d.telefono,
              :hora        => d.hora
            })
            
            p.save
          end
        end
      end
      
      # If all sections are valid, then FINALLY!
      if cliente_valid && facturar_valid && operaciones_valid
        @project.con_datos_pendientes_promote    = false
        @project.datos_de_confirmacion_completos = true
        @project.save
        
        redirect_to :controller => "projects", :action => "confirmation_data_of_order", :id => @project.uid, :type => @project.type
      end
      
    else
      # From GET, let's load it up, everybody!
      
      # We preload the form data with the data from the DB if we already have
      # it, or the initial set of data if we are filling this form for the
      # very first time
      if @project.promote_data_edited?
        if @project.factura_fecha_facturacion.nil?
          factura_fecha_facturacion = ""
          factura_hora_facturacion  = ""
          hora_am_pm_f              = ""
        else
          factura_fecha_facturacion = @project.factura_fecha_facturacion.strftime("%d/%m/%y")
          factura_hora_facturacion  = @project.factura_fecha_facturacion.strftime("%I%M")
          hora_am_pm_f              = @project.factura_fecha_facturacion.strftime("%p")
        end
        
        if @project.monto_adelanto.nil? || @project.monto_adelanto == 0
          no_amount = true
        else
          no_amount= false
        end
        
        if @project.dias_plazo.nil? || @project.dias_plazo == 0 || @project.dias_plazo == ""
          no_dias_plazo = true
        else
          no_dias_plazo = false
        end
        
        if @project.factura_contraentrega.nil?
          contraentrega = ""
        else
          contraentrega = @project.factura_contraentrega? ? "1" : "0"
        end
        
        if @project.monto_odt.nil?
          amount = "0.00"
        else
          amount = "%0.2f" % @project.monto_odt
        end
        
        currency                     = @project.moneda_odt
        cliente_razon_social         = @project.cliente_razon_social
        cliente_ruc                  = @project.cliente_ruc
        cliente_direccion            = @project.cliente_direccion
        cliente_contacto             = @project.cliente_contacto
        cliente_telefono_fijo        = @project.cliente_telefono_fijo
        cliente_telefono_movil       = @project.cliente_telefono_movil
        cliente_email                = @project.cliente_email
        factura_necesita_odt         = @project.factura_necesita_odt
        factura_razon_social         = @project.factura_razon_social
        factura_direccion_fiscal     = @project.factura_direccion_fiscal
        factura_ruc                  = @project.factura_ruc
        factura_descripcion          = @project.factura_descripcion
        factura_con_adelanto         = (no_amount ? "0" : "1")
        factura_tipo_adelanto        = (no_amount ? "" : "M")
        factura_porcentaje           = ""
        monto_adelanto               = "%0.2f" % @project.monto_adelanto unless no_amount
        factura_contraentrega        = contraentrega
        dias_plazo                   = (no_dias_plazo ? "" : @project.dias_plazo)
        factura_contacto_facturacion = @project.factura_contacto_facturacion
        factura_telefono_fijo        = @project.factura_telefono_fijo
        factura_telefono_movil       = @project.factura_telefono_movil
        factura_email                = @project.factura_email
        factura_direccion            = @project.factura_direccion
        factura_observaciones        = @project.factura_observaciones
        se_necesita_supervisor       = @project.se_necesita_supervisor
        
        # Ajaxy Client name
        if @project.factura_account.nil?
          factura_cliente = ""
        else
          factura_cliente = @project.factura_account.name
        end
      else # Promoting for the first time
        
        if @project.contact.nil?
          cliente_contacto             = ""
          cliente_telefono_fijo        = ""
          cliente_telefono_movil       = ""
          cliente_email                = ""
          
          factura_contacto_facturacion = ""
          factura_telefono_fijo        = ""
          factura_telefono_movil       = ""
          factura_email                = ""
        else
          cliente_contacto             = @project.contact.full_name
          cliente_telefono_fijo        = @project.contact.phone_work
          cliente_telefono_movil       = @project.contact.phone_mobile
          cliente_email                = @project.contact.email1
          
          factura_contacto_facturacion = @project.contact.full_name
          factura_telefono_fijo        = @project.contact.phone_work
          factura_telefono_movil       = @project.contact.phone_mobile
          factura_email                = @project.contact.email1
        end
        
        if @project.fecha_de_entrega_odt.nil?
          factura_fecha_facturacion    = ""
          factura_hora_facturacion     = ""
          hora_am_pm_f                 = ""
        else
          factura_fecha_facturacion    = @project.fecha_de_entrega_odt.strftime("%d/%m/%y")
          factura_hora_facturacion     = @project.fecha_de_entrega_odt.strftime("%I%M")
          hora_am_pm_f                 = @project.fecha_de_entrega_odt.strftime("%p")
        end
          
        
        currency                     = ""
        amount                       = "%.2f" % (@project.opportunity.amount || 0.00)
        cliente_razon_social         = @project.account.name
        cliente_ruc                  = @project.account.ruc
        cliente_direccion            = @project.account.billing_address_street
        factura_necesita_odt         = "0"
        factura_razon_social         = @project.account.name
        factura_direccion_fiscal     = ""
        factura_ruc                  = @project.account.ruc
        factura_descripcion          = @project.nombre_proyecto
        factura_con_adelanto         = "0"
        factura_tipo_adelanto        = ""
        factura_observaciones        = ""
        monto_adelanto               = ""
        factura_direccion            = @project.account.extras.factura_direccion
        factura_cliente              = ""
        se_necesita_supervisor       = "-1"
        
        if @project.account.extras.dias_plazo.nil?
          factura_contraentrega = ""
          dias_plazo            = ""
        elsif @project.account.extras.dias_plazo == 0
          factura_contraentrega = "1"
          dias_plazo            = ""
        else
          factura_contraentrega = "0"
          dias_plazo            = @project.account.extras.dias_plazo
        end
      end
      
      # Verifications on things not affected by either editing first time
      # or not
      if @project.fecha_de_desmontaje.nil?
        fecha_de_desmontaje = ""
        hora_de_desmontaje  = ""
        hora_am_pm_d        = "AM"
      else
        fecha_de_desmontaje = @project.fecha_de_desmontaje.strftime("%d/%m/%y")
        hora_de_desmontaje  = @project.fecha_de_desmontaje.strftime("%I%M")
        hora_am_pm_d        = @project.fecha_de_desmontaje.strftime("%p")
      end
      
      # Ok, LOAD!
      
      @form_cliente.load_values({
        "cliente_razon_social"         => cliente_razon_social,
        "cliente_ruc"                  => cliente_ruc,
        "cliente_direccion"            => cliente_direccion,
        "cliente_contacto"             => cliente_contacto,
        "cliente_telefono_fijo"        => cliente_telefono_fijo,
        "cliente_telefono_movil"       => cliente_telefono_movil,
        "cliente_email"                => cliente_email,
      })
      
      @form_facturar.load_values({
        "factura_necesita_odt"         => factura_necesita_odt,
        "factura_cliente"              => factura_cliente,
        "factura_direccion_fiscal"     => factura_direccion_fiscal,
        "factura_fecha_facturacion"    => factura_fecha_facturacion,
        "factura_hora_facturacion"     => factura_hora_facturacion,
        "hora_am_pm_f"                 => hora_am_pm_f,
        "factura_descripcion"          => factura_descripcion,
        "factura_con_adelanto"         => factura_con_adelanto,
        "factura_tipo_adelanto"        => factura_tipo_adelanto,
        "monto_adelanto"               => monto_adelanto,
        "factura_contraentrega"        => factura_contraentrega,
        "dias_plazo"                   => dias_plazo,
        "factura_contacto_facturacion" => factura_contacto_facturacion,
        "factura_telefono_fijo"        => factura_telefono_fijo,
        "factura_telefono_movil"       => factura_telefono_movil,
        "factura_email"                => factura_email,
        "factura_direccion"            => factura_direccion,
        "fecha_de_desmontaje"          => fecha_de_desmontaje,
        "hora_de_desmontaje"           => hora_de_desmontaje,
        "hora_am_pm_d"                 => hora_am_pm_d,
        "monto_de_venta"               => amount,
        "forma_de_pago"                => @project.forma_de_pago,
        "moneda"                       => currency,
        "incluye_igv"                  => @project.incluye_igv_odt,
        "factura_observaciones"        => factura_observaciones
      })
      
      @form_operaciones.load_values({
        "solo_entrega"                 => @project.solo_entrega,
        "con_instalacion"              => @project.con_instalacion,
        "se_necesita_supervisor"       => se_necesita_supervisor,
        "recojo_de_producto"           => @project.recojo_de_producto,
        "colores_aprobados"            => @project.colores_aprobados,
        "igual_al_arte_adjuntado"      => @project.igual_al_arte_adjuntado,
        "igual_al_codigo_pantones"     => @project.igual_al_codigo_pantones,
        "presentar_muestra_de_color"   => @project.presentar_muestra_de_color,
        "graficas_aprobadas"           => @project.graficas_aprobadas,
        "graf_igual_a_muestra"         => @project.graf_igual_a_muestra,
        "graf_igual_a_pantones"        => @project.graf_igual_a_pantones,
        "graf_presentar_muestra"       => @project.graf_presentar_muestra,
        "observaciones"                => @project.observaciones,
        "confirmar_medidas"            => @project.confirmar_medidas,
      })
      
      @puntos = Array.new
      
      if @project.puntos_de_entrega.empty?
        punto = Fionna.new("promote_punto")
        
        unless @project.contact.nil?
          punto.punto    = ""
          punto.contacto = @project.contact.full_name
          punto.telefono = @project.contact.phone_work.to_s + "\n" + @project.contact.email1.to_s + "\n"
        end
        
        @puntos << punto
      else
        @project.puntos_de_entrega.each do |p|
          punto = Fionna.new("promote_punto")
          punto.load_values p.attributes
          
          @puntos << punto
        end
      end
    end
  end
  
  
  def toggle_attached_file
    @detalle = Detalle.find params[:did]
    file     = params[:fid]
    
    mlist = @detalle.marcados.split "/"
    
    if mlist.include? file
      mlist.delete file
    else
      mlist << file
    end
    
    @detalle.marcados = mlist.join "/"
    @detalle.save
    
    true
    render :nothing => true
  end
  
  
  def confirmation_data_of_order
    @puntos  = @project.puntos_de_entrega
  end
  
  
  def print_order
    @details = @project.detalles
    render :layout => false
  end
  
  
  def export_orders
    # Orders now
    @list = Proyecto.full_list
    
    s = ''
    
    @list.each do |p|
      if p.incluye_igv_odt
        monto = p.monto_de_venta
      else
        monto = p.monto_de_venta / 1.19
      end
      
      s = s + '"' + p.orden_id.to_s + '",' +
              '"' + p.account.name + '",' +
              '"' + monto.to_s + '",' +
              '"' + p.fecha_creacion_odt.strftime("%d/%m/%Y") + '"' + "\n"
    end
    
    render :text => s
  end
  
  
  def void_order
  # Voids (anula) the Order
    @form = Fionna.new "void_order"
    
    raise "CANNOT_VOID_ODT_WITH_FACTURAS" if @project.has_facturas_or_boletas?
    
    if request.post?
      @form.load_values params
      @form.empresa = @project.empresa_vendedora.to_s
      
      if @form.valid?
        @project.anulado          = true
        @project.motivo_anulacion = @form.motive
        @project.save
        set_project_status E_ANULADO
        
        Mail.void_notification(session[:user][:id], @project.id)
        
        redirect_to_show_project
      end
    end
  end
  
  
  def invoice
    if @project.autorizado_para_facturar?
      redirect_to_show_project 
    
    elsif @project.tipo_nuevo_proyecto?
      if @project.facturation_data_complete?
        @project.autorizado_para_facturar = true
        @project.save
        Mail.odt_invoice(session[:user][:id], @project.id)
        
        redirect_to_show_project
      end
    else
      @project.autorizado_para_facturar = true
      @project.save
      redirect_to_show_project
    end
  end
  
  
  def mark_post_venta
    if @project.active? && !@project.anulado?
      @project.postvendido  = true
      @project.fecha_pventa = Time.now
      @project.save
    end
    
    redirect_to :action => "orders"
  end
  
  
  def op_accept_date
  # Operations stuff. Automatically accepts the date of entrega for an ODT.
  # We double-check here that the date is not nil.
    unless @project.fecha_de_entrega_odt.nil?
      set_project_status E_OPERACIONES_TERMINADO
      Mail.fecha_entrega_accepted_by_op(session[:user][:id], @project.id)
    end
    
    redirect_to :action => "projects" 
  end
  
  
  def op_date
    @messages = Mensaje.operaciones @project.id
    
    @mform    = Fionna.new "mensajes"
    @sform    = Fionna.new "op_set_supervisor"
    @isdform  = Fionna.new "op_installation_start_date"
    @denyform = Fionna.new "op_deny"
    
    if request.post?
      # Is he requesting the Supervisor select form?
      if params[:sup]
        @sform.load_values params
        
        if @sform.valid?
          @project.supervisor_asignado = @sform.supervisor
          @project.save
          redirect_to :action => "op_date", :id => @project.uid, :type => @project.type

        end
      
      # No? Is he requesting the Start Date of Installation?
      elsif params[:inicio] && is_operations?
        @isdform.load_values params
        
        if @isdform.valid?
          @project.fecha_de_inicio_instalacion = process_date_and_hour_2(@isdform.fecha_de_inicio, @isdform.hora_de_inicio, @isdform.hora_inicio_am_pm)
          @project.save
          
          redirect_to :action => "op_date"
        end
      
      # Not either? Then, is he trying to deny this project?
      elsif params[:deny]
        @denyform.load_values params
        
        if @denyform.valid?
          @project.area.en_operaciones      = false
          @project.area.ingreso_operaciones = nil
          @project.area.salida_operaciones  = nil
          @project.area.estado_operaciones  = nil
          @project.area.save
          
          Mail.operaciones_denied(session[:user], @project, @denyform.motivo)
          
          redirect_to_show_project
          return
        end
      end
    else
      # He came by GET!
      if @project.supervisor_asignado.nil?
        @sform.supervisor = "-1"
      else
        @sform.supervisor = @project.supervisor_asignado
      end
      
      unless @project.fecha_de_inicio_instalacion.nil?
        d = @project.fecha_de_inicio_instalacion
        @isdform.fecha_de_inicio   = d.strftime("%d/%m/%y")
        @isdform.hora_de_inicio    = d.strftime("%I%M")
        @isdform.hora_inicio_am_pm = d.strftime("%p")
      end
    end
  end
  
  
  def op_date_item
  # Define an item of Fechas Parciales de Entrega
    @form = Fionna.new "op_date_item"
    
    if request.post?
      @form.load_values params
      redirect = true
      
      # Ok, so who is talking here?
      if is_executive?
        if params[:a] # Acceptance by Exec
          @date.accepted!
          @date.observaciones = @form.observaciones
          @date.save
          log_fecha_de_entrega "Aceptada por el Ejecutivo"
          update_project_fechas_de_entrega_status
          Mail.fecha_entrega_accepted_by_exec(session[:user], @date)
          
          # Is this one of those already accepted Projects?
          if @project.notificado_como_venta_asegurada?
            #@project.promote_to_odt
          end
        end
        
        if params[:r] # Redefinition by Exec
          if @form.valid?
            fecha = process_date_and_time(@form, "entrega")
            @date.redefine_date! fecha
            @date.awaiting_approval_op!
            @date.observaciones = @form.observaciones
            @date.save
            log_fecha_de_entrega "Replanteada por el Ejecutivo"
            update_project_fechas_de_entrega_status
            Mail.fecha_entrega_redefined_by_exec(session[:user], @date)
          end
        else
          redirect = false
        end
        
      elsif is_operations?
        if params[:a] # Acceptance by Op
          @date.accepted!
          @date.observaciones = @form.observaciones
          @date.save
          log_fecha_de_entrega "Aceptada por Operaciones"
          update_project_fechas_de_entrega_status
          Mail.fecha_entrega_accepted_by_op(session[:user], @date)
        end
        
        if params[:r] # Redefinition by Op
          if @form.valid?
            fecha = process_date_and_time(@form, "entrega")
            @date.redefine_date! fecha
            @date.awaiting_approval_ex!
            @date.observaciones = @form.observaciones
            @date.save
            log_fecha_de_entrega "Replanteada por Operaciones"
            update_project_fechas_de_entrega_status
            Mail.fecha_entrega_redefined_by_op(session[:user], @date)
          end
        end
      end
      
      redirect_to :action => "op_date", :id => @project.uid, :type => @project.type if redirect
    end
  end
  
  
  def op_date_modify
  # Modifies the date of Fecha de Entrega Parcial of ODT via password.
  
    unless @date.can_be_modified?
      redirect_to_show_project
      return
    end
  
  # Two stages: first is a user defines a date, motive and puts his password.
  # Second stage is the other user approves the thing.
  # Let's see in which stage we are:
    if @date.awaiting_modification_approval_op? || @date.awaiting_modification_approval_ex?
      @stage = 2
      @form  = Fionna.new "op_date_modify_2"
      
      # We want to know who is the one who has to authorize
      if @date.awaiting_modification_approval_op?
        # Operations has to authorize
        @label = "Operaciones"
        @form.set_property_of "auth", { "function" => "validate_op_date_redef_op" }
      else
        # The Executive has to authorize
        @label = "Ejecutivo"
      end
    else
      @stage = 1
      @form  = Fionna.new "op_date_modify_1"
    end
    
    if request.post?
      @form.load_values params
      
      # STAGE 1
      if @stage == 1
        @form.empresa = @project.empresa_vendedora.to_s
        
        if @form.auth_exec.strip == "" && @form.auth_op.strip == ""
          @form.set_property_of "auth_exec", { "mandatory" => true }
          @form.set_property_of "auth_op",   { "mandatory" => true }
        end
        
        if @form.valid?
          fecha                        = process_date_and_time(@form, "entrega")
          @date.mod_fecha              = fecha
          @date.mod_motivo             = @form.motive
          @date.mod_solicitado_por     = @form.solicitado_por
          @date.mod_propuesto_por_user = session[:user][:id]
          
          # Area that solicited the request
          if is_executive?
            @date.mod_propuesto_por_area = "C"
          elsif is_operations?
            @date.mod_propuesto_por_area = "O"
          else
            raise "op_date_modify: Unexpected area proposing modification"
          end
          
          exec_approved = (@form.auth_exec != "")
          op_approved   = (@form.auth_op != "")
          
          @date.save
          
          # Did both put their passwords already? Then we update the whole
          # thing right now and notify
          if exec_approved && op_approved
            @date.modify_date! fecha
            @date.accepted!
            log_fecha_de_entrega "Modificada por solicitud de #{@date.modification_proposed_by_area}"
            update_project_fechas_de_entrega_status
            Mail.fecha_entrega_modified(session[:user], @date)
          else
            # Nope, they didn't put both passwords. We gotta set up the
            # stage 2 of the thing
            if exec_approved
              @date.awaiting_modification_approval_op!
              log_fecha_de_entrega "Esperando autorizaci&oacute;n de Operaciones para modificar a solicitud de #{@date.modification_proposed_by_area}"
              update_project_fechas_de_entrega_status
              Mail.fecha_entrega_awaiting_auth(session[:user], @date, :op)
            else
              @date.awaiting_modification_approval_ex!
              log_fecha_de_entrega "Esperando autorizaci&oacute;n del Ejecutivo para modificar a solicitud de #{@date.modification_proposed_by_area}"
              update_project_fechas_de_entrega_status
              Mail.fecha_entrega_awaiting_auth(session[:user], @date, :ex)
            end
          end
          
          redirect_to :controller => "projects", :action => "op_date", :id => @project.uid, :type => @project.type
        end
        
      else
        @form.empresa = @project.empresa_vendedora.to_s
        
        # STAGE 2
        if @form.valid?
          @date.modify_date! @date.mod_fecha
          @date.accepted!
          log_fecha_de_entrega "Modificada por solicitud de #{@date.modification_proposed_by_area}"
          update_project_fechas_de_entrega_status
          Mail.fecha_entrega_modified(session[:user], @date)
          
          redirect_to :controller => "projects", :action => "op_date", :id => @project.uid, :type => @project.type
        end
        
      end
    else
      # He came from GET
      if @stage == 1
        load_date_and_time @form, "entrega", @date.fecha
      end
    end
  end
  
  
  def production
  end
  
  
  def production_edit
    if request.post?
      @entries = multirow_load("production", :fecha_fecha, :fecha_hora, :fecha_am_pm, :cantidad)
      
      if params[:save]
        is_valid = multirow_validate(@entries)
        
        if is_valid
          # Check out the quantities, can't exceed the quantity of the @date
          qty = @entries.inject(0) { |sum, e| sum + e.cantidad.to_i }
          
          if qty > @date.cantidad
            is_valid = false
            @quantity_error_msg = true
          end
        end
        
        # Ok, this is it
        if is_valid
          TerminadosEnPlanta.reset @date
          
          @entries.each do |d|
            i = TerminadosEnPlanta.new
            
            i.fechas_de_entrega_id = @date.id
            i.fecha                = process_date_and_time(d, "fecha")
            i.cantidad             = d.cantidad
            i.save
          end
          
          redirect_to :action => "production", :id => @project.orden_id
        end
      end
    else
      @entries = []
      
      if @date.terminados_en_planta.empty?
        @entries << Fionna.new("production")
      else
        @date.terminados_en_planta.each do |i|
          fd = Fionna.new "production"
          load_date_and_time(fd, "fecha", i.fecha)
          fd.cantidad = i.cantidad
          
          @entries << fd
        end
      end
    end
  end
  
  
  def auto_complete_for_account_name
    super_auto_complete_for_account_name
  end
  
  
  def toggle_urgency
    @project.muy_urgente = !@project.muy_urgente?
    @project.save
    
    redirect_to_show_project
  end
  
  
  def history_of_dates
    @dates  = @project.fechas_de_entrega_log
  end
  
  
  def remove_op
    unless params[:id].nil?
      @p = Proyecto.find params[:id]
      @p.area.en_operaciones      = false
      @p.area.ingreso_operaciones = nil
      @p.area.save
    end
  end
  
  
  def unmark_odt_for_export
    unless params[:id].nil?
      @p = Proyecto.find_odt params[:id]
      @p.orden_exportada    = false
      @p.proyecto_exportado = false
      @p.save
    end
  end
  
  
  def create_gr
  # Create garant\EDa or reclamo
    @form = Fionna.new "create_gr"
    
    if request.post?
      @form.load_values params
      @form.empresa = @project.empresa_vendedora.to_s
      
      if @form.valid?
        op                 = @project.opportunity.clone
        op.id              = Opportunity.create_guid
        op.name            = @form.description
        op.date_entered    = Time.now
        op.date_modified   = Time.now
        op.deleted         = false
        op.used_in_vera    = true
        op.amount          = 0.00
        op.amount_usdollar = 0.00
        op.save
        
        oa = AccountsOpportunities.new
        oa.id             = Opportunity.create_guid
        oa.opportunity_id = op.id
        oa.account_id     = @project.account_id
        oa.date_modified  = Time.now
        oa.deleted        = "0"
        oa.save
        
        pr = @project.clone
        pr.tipo_proyecto           = @form.gr_type
        pr.otro_tipo               = ""
        pr.fecha_creacion_proyecto = Time.now
        pr.opportunity_id          = op.id
        pr.con_orden_de_trabajo    = false
        pr.orden_id                = 0
        pr.fecha_creacion_odt      = nil
        
        data = {}
        set_default_values_for_a_new_project(data)
        
        pr.update_attributes(data)
        pr.save
        
        bootstrap_project(pr)
        
        # Add a reference of this GR to this project
        ref             = GrioProyecto.new
        ref.proyecto_id = @project.id
        ref.grio_id     = pr.id
        ref.save
        
        redirect_to :action => "edit_project", :id => pr.uid, :type => pr.type
      end
    else
      # GET
      @form.description = @project.nombre_proyecto
    end
  end
  
  
  def empty_ruc
    @op     = Opportunity.find params[:id]
    @client = @op.accounts[0]
    
    redirect_to(:action => "new", :id => @op.id) if @client.ruc
  end
  
  
  def quicksearch
    if params[:qs]
      qs = params[:qs]
      
      begin
        if qs.length > 1
          if qs[0].chr.downcase == "p"
            p = Proyecto.find_by_id qs[1..-1]
          
          elsif qs[0].chr.downcase == "o"
            p = Proyecto.find_odt qs[1..-1]
          
          else
            p = Proyecto.find_odt qs
          end
        end
      rescue
        p = nil
      end
      
      redirect_to_show_project(p) if p
    end
  end
  
  
  def delete_opportunity
    @form = Fionna.new "delete_opportunity"
    
    raise "CANNOT_DELETE_OPP_WITH_FACTURAS" if @project.has_facturas_or_boletas?
    
    if request.post?
      @form.load_values params
      @form.empresa = @project.empresa_vendedora.to_s
      
      if @form.valid?
        op = @project.opportunity
        op.sales_stage = "Closed Lost"
        op.deleted     = "1"
        op.save
        
        redirect_to :action => current_tab
      end
    end
  end
  
  
  def confirmation_docs_popup
    @docs = @project.get_confirmation_docs
    
    if request.post?
      if @project.tipo_nuevo_proyecto?
        copy_data_file(params[:file], @project.confirmation_docs_path) if params[:file]
        redirect_to :action => "confirmation_docs_popup", :id => @project.id
        has_uploaded = true
      end
    end
    
    render :layout => "popup" unless has_uploaded
  end
  
  
  def get_confirmation_doc
    send_data_file_to_browser(@project.confirmation_docs_path, params[:fid])
  end
  
  def delete_costs_doc
    #delete_data_file(@project.costs_path, params[:fid])
    redirect_to :action => "costs_docs_popup", :id => @project.id
  end
  
  def delete_confirmation_doc
    delete_data_file(@project.confirmation_docs_path, params[:fid])
    redirect_to :action => "confirmation_docs_popup", :id => @project.id
  end
  
  
  def costs_docs_popup
    @docs = @project.get_costs_files
    
    if request.post?
      if @project.tipo_nuevo_proyecto?
        copy_data_file(params[:file], @project.costs_path) if params[:file]
        redirect_to :action => "costs_docs_popup", :id => @project.id
        has_uploaded = true
      end
    end
    
    render :layout => "popup" unless has_uploaded
  end
  
  
  def change_empresa_or_type
    @form = Fionna.new "change_empresa_or_type"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        @project.empresa_vendedora = @form.empresa
        @project.save
        
        Proyecto.change_type @project.id, @form.tipo, :project
        
        redirect_to :action => "show", :id => @project.uid, :type => @project.type
      end
      
    else
      @form.empresa = @project.empresa_vendedora.to_s
      @form.tipo    = @project.tipo_proyecto
    end
  end
  
  
  def notifications
    @notifications = @project.notificaciones
  end
  
  
  def redefine_facturated_price
    # Verify that it can really have its price redefined
    redirect_to :controller => "dashboard", :action => "index" if @project.facturated_remainder == 0.00
    
    # We have two stages. First, the Executive proposes a new price and
    # gets it approved by Comercial.
    # Second, Facturaci\F3n approves the whole thing.
    @redef = @project.op_fact_price_redef
    
    if @project.facturated_price_redefined?
      @stage = 1
    else
      @stage = 2
    end
    
    
    # STAGE 1
    if @stage == 1
      @form = Fionna.new "redefine_facturated_price_stage_1"
      
      if request.post?
        @form.load_values params
        @form.empresa = @project.empresa_vendedora.to_s
        
        if @form.valid?
          # Some extra verifications
          ok = true
          
          monto = @form.monto_de_venta.to_f
          
          if monto < @project.monto_facturado || monto == 0.00
            @form.set_property_of :monto_de_venta, "error_msg" => "El nuevo monto no puede ser menor a lo facturado"
            ok = false
          end
          
          if ok
            ProyectoFactPriceRedef.destroy_all ["proyecto_id=?", @project.id]
            
            redef = ProyectoFactPriceRedef.new({
              :proyecto_id => @project.id,
              :old_monto   => @project.monto_de_venta_sin_igv,
              :new_monto   => @form.monto_de_venta,
              :motivo      => @form.motivo,
              :auth_exec   => true,
              :auth_fact   => false
            })
            redef.save
            
            Mail.facturated_price_redef_pending(session[:user][:id], @project, redef)
            
            redirect_to :action => "redefine_facturated_price", :id => @project.orden_id
          end
        end
      end
    else
      
      # STAGE 2
      
      @form  = Fionna.new "redefine_facturated_price_stage_2"
      @redef = @project.op_fact_price_redef
      
      if request.post?
        @form.load_values params
        @form.empresa = @project.empresa_vendedora.to_s
        
        if @form.valid?
          @redef.auth_fact = true
          @redef.save
          
          # Ok, let's change it!
          @project.monto_odt       = @redef.new_monto
          @project.incluye_igv_odt = false
          @project.save
          
          Mail.facturated_price_redef_finished(session[:user][:id], @project, @redef)
          
          redirect_to :action => "show", :id => @project.uid, :type => @project.type
        end
      end
    end
  end
  
  
  def variable_cost
    @oid     = @project.orden_id
    @project = Proyecto.find_odt @oid
  end
  
  
  def account_blocked
  end
  
  
  def set_standby
    if params[:off]
      @project.en_standby = false
      @project.save
    
      Mail.odt_standby(session[:user][:id], @project)
      
      redirect_to_show_project
      return true
    else
      @form = Fionna.new "set_standby"
      
      if request.post?
        @form.load_values params
        @form.empresa = @project.empresa_vendedora.to_s
        
        if @form.valid?
          @project.en_standby = true
          @project.save
          
          Mail.odt_standby(session[:user][:id], @project)
          
          redirect_to_show_project
          return true
        end
      end
    end
  end
  
  
  def not_found
  end
  
  
  def validate_orders
    set_current_tab "validate_orders"
    #@orders = Proyecto.list_of_orders_to_validate
  end
  
  
  def edit_fechas_de_entrega
    if @project.fechas_de_entrega.empty?
      @new = true
    else
      @new = false
    end
    
    form_definition = "new_fechas_de_entrega"
    
    if request.post?
      if @new
        @dates = multirow_load(form_definition, :fecha_fecha, :fecha_hora, :fecha_am_pm, :detalle, :cantidad)
      else
        params[:row_delete] = nil
        params[:row_add]    = nil
        @dates = multirow_load(form_definition, :fecha_fecha, :fecha_hora, :fecha_am_pm,  :detalle, :cantidad)
      end
      
      valid = params[:save] && multirow_validate(@dates)
      
      if valid && @new == false
        @dates.each_with_index do |d, i|
          plant_qty = @project.fechas_de_entrega[i].finished_in_plant_quantity
          
          if d.cantidad.to_i < plant_qty
            d.set_error_msg_of "cantidad", "Cantidad no puede ser menor a lo ya entregado en Planta (#{plant_qty})"
            valid = false
          end
        end
      end
      
      
      # Yay, go!
      if valid
        FechasDeEntrega.reset @project if @new
  
  project_date = nil
        
        @dates.each_with_index do |d, i|
          if @new
            f        = FechasDeEntrega.new
            fecha    = process_date_and_time(d, "fecha")
            cantidad = d.cantidad
            detalle  = d.detalle
            log_msg  = "Fecha inicial"
          else
            f        = @project.fechas_de_entrega[i]
            fecha    = process_date_and_time(d, "fecha")
            cantidad = d.cantidad
            detalle  = d.detalle
            log_msg  = "Datos de Fechas editados por el Ejecutivo"
          end
        
          f.proyecto_id = @project.id
          f.fecha         = fecha
          f.cantidad      = cantidad
          f.detalle       = detalle
          f.observaciones = ''
          f.save
    
    project_date = fecha
          
          f.log session[:user][:id], log_msg
          Mail.fecha_entrega_data_modified_by_executive(session[:user], @project)
        end
  
  unless project_date.nil?
    @project.fecha_de_entrega_odt = project_date
    @project.save
  end
        
        if @new
          redirect_to :action => "edit_details", :id => @project.uid, :type => @project.type
        else
          redirect_to_show_project
        end
      end
    else
      if @new
        # Creating for the first time
        fd = Fionna.new form_definition
        load_date_and_time fd, "fecha", @project.fecha_de_entrega_odt
        fd.detalle      = @project.nombre_proyecto
        fd.cantidad     = ""
        
        @dates = [fd]
        
      else
        # Nope, editing existing
        @dates = []
        
        @project.fechas_de_entrega.each do |f|
          fd = Fionna.new form_definition
          fd.detalle      = f.detalle
          fd.cantidad     = f.cantidad
    
          load_date_and_time fd, "fecha", @project.fecha_de_entrega_odt
          
          @dates << fd
        end
      end
    end
  end
  
  
  def costs_are_editable?
    if is_executive? && (@project.area.estado_costos != E_COSTOS_TERMINADO)
      return true
    else
      return false
    end
  end
  
  
  
  ##########
  #protected
  ##########
  
  def process_date(this)
  # A convenience method for DRY ("Don't Repeat Yourself")
    fecha_entrega = @form.send("fecha_entrega_" + this)
    hora_entrega  = @form.send("hora_entrega_" + this)
    am_pm         = @form.send("hora_am_pm_" + this)
    
    return process_date_and_hour_2(fecha_entrega, hora_entrega, am_pm)
  end
  
  
  def process_notification_for_urgency(project)
  # For DRY. Processes the urgency checkboxes for a project and sends
  # mail for every urgent box marked
    Mail.urgent_notification(session[:user][:id], project.id, A_DISENO) if project.urgente_diseno?
    Mail.urgent_notification(session[:user][:id], project.id, A_PLANEAMIENTO) if project.urgente_planeamiento?
    Mail.urgent_notification(session[:user][:id], project.id, A_COSTOS) if project.urgente_costos?
  end
  
  
  def log_fecha_de_entrega(comments)
    @date.log session[:user][:id], comments
  end
  
  
  def change_fecha_de_entrega_and_notify(project, new_date, motive, area)
    old_date                     = project.fecha_de_entrega_odt
    project.fecha_de_entrega_odt = new_date
    project.update
    
    log_fecha_de_entrega(project)
    
    Mail.fecha_entrega_modified_with_authorization(session[:user][:id], project.id, motive, old_date, new_date, area)
  end
  
  
  def set_project_status(status)
    @project.set_status status, session[:user][:id]
  end
  
  
  def set_default_values_for_a_new_project(data)
    data[:fecha_creacion_proyecto]    = Time.now
    data[:con_orden_de_trabajo]       = false
    data[:orden_id]                   = 0
    data[:fecha_creacion_odt]         = nil
    data[:colores_aprobados]          = false
    data[:igual_al_arte_adjuntado]    = false
    data[:igual_al_codigo_pantones]   = false;
    data[:presentar_muestra_de_color] = false;
    data[:graficas_aprobadas]         = false;
    data[:graf_igual_a_muestra]       = false;
    data[:graf_igual_a_pantones]      = false;
    data[:graf_presentar_muestra]     = false;
    data[:forma_de_pago]              = "";
    data[:incluye_igv_odt]            = false;
    data[:confirmar_medidas]          = false;
    data[:facturado]                  = F_POR_FACTURAR;
    data[:postvendido]                = false;
    data[:fecha_pventa]               = nil;
    data[:proyecto_exportado]         = false;
    data[:orden_exportada]            = false;
    data[:monto_odt]                  = 0;
    data[:moneda_odt]                 = '';
    data[:monto_activo]               = 0;
    data[:monto_credito]              = 0;
    data[:observaciones_validacion]   = "";
    data[:orden_relacionada]          = nil;
    data[:costo_compras]              = 0;
    data[:costo_insumos]              = 0;
    data[:costo_servicios]            = 0;
    data[:migrado_intranet]           = 0;
  end
  
  
  def bootstrap_project(project)
    # Mark the Opportunity as having a project
    project.opportunity.with_project = true
    project.opportunity.save
    
    # If it's an Internal or Other Order type, we mark the Opportunity with
    # the special delete and as Closed Won
    if [T_ORDEN_INTERNA, T_OTRO].include? project.tipo_proyecto.to_i
      project.opportunity.deleted      = true
      project.opportunity.used_in_vera = true
      project.opportunity.sales_stage  = "Closed Won"
      project.opportunity.save
    end
    
    # We create the directories for Project and Costs
    FileUtils::mkdir project.costs_path unless File.exists?(project.costs_path)
    FileUtils::mkdir project.project_path unless File.exists?(project.project_path)
    
    # Initialize its status
    project.init_status(session[:user][:id])
    
    # Mail notifications for urgency
    process_notification_for_urgency(project)
    
    if project.tipo_proyecto == T_ORDEN_INTERNA
      Mail.internal_order_notification(session[:user][:id], project.id)
    end
  end
  
  
  def has_read_access_for_this_project
    # Internally, a Project and an Order are the same object. So we do a check
    # for the right allow according to the object type.
    if @project.con_orden_de_trabajo?
      return false unless has_read_access_for :orders
    else
      return false unless has_read_access_for :projects
    end
    
    return true
  end
  
  
  def has_write_access_for_this_project
    # Internally, a Project and an Order are the same object. So we do a check
    # for the right allow according to the object type.
    if @project.con_orden_de_trabajo?
      return false unless has_write_access_for :orders
    else
      return false unless has_write_access_for :projects
    end
    
    return true
  end
  
  
  def update_project_fechas_de_entrega_status
    @project.reload
    @project.update_fechas_de_entrega_status!
    set_project_status @project.area.estado_operaciones
    
    # Autopromote to ODT if it's all approved
    if @project.con_orden_de_trabajo? == false && @project.all_fechas_de_entrega_accepted?
      @project.promote_to_odt
    end
  end
  
  
  # End of protected methods
end
