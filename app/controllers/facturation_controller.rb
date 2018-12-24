class FacturationController < ApplicationController
  before_filter :preload_project, :only => ["order_facturation", "non_factura", "order_facturas", "new_factura_2", "new_factura_3", "order_guias", "new_guia_2", "new_guia_3"]
  
  before_filter :preload_factura, :only => ["show_factura", "edit_factura", "void_factura", "blank_factura", "factura_guias", "factura_add_guias", "print_factura", "print_factura_preview", "print_factura_pdf"]
  
  before_filter :preload_guia, :only => ["edit_guia", "show_guia", "void_guia"]
  
  before_filter :check_access
  
  before_filter :cannot_access_if_printed, :only => ["print_factura", "edit_factura", "print_factura_preview", "print_factura_pdf", "void_factura", "blank_factura"]
  
  before_filter :check_if_processable, :only => ["order_facturation", "order_facturas", "new_factura_2", "new_factura_3"]
  
  
  def facturas
    set_current_tab "facturas"
    @type = "f"
    panel_facturas_boletas
  end
  
  
  def boletas
    set_current_tab "boletas"
    @type = "b"
    panel_facturas_boletas
  end
  
  
  def panel_facturas_boletas
    @tab       = "facturas_boletas_#{@type}"
    @form      = Fionna.new "panel_facturas_boletas"
    conditions = " AND empresa IN #{companies_sql_list}"
    
    reset_filter(@tab) if params[:reset_filters]
    set_filter(@tab, params) if params[:q]
    
    # Show all?
    if params[:show_all]
      @show_all = true
    else
      @show_all = false
    end
    
    # Limit the Empresas list to only the ones this user can see
    set_companies_for @form
    
    @form.load_values get_filter(@tab)
    
    if @form.valid?
      if @form.empresa_vendedora != "-1" && can_see_company?(@form.empresa_vendedora)
        conditions += "AND empresa='#{@form.empresa_vendedora}'"
      end
      
      conditions += "AND anulada='1'" if @form.estado == "ANULADA"
      conditions += "AND en_blanco='0' AND anulada='0'" if @form.estado == "EMITIDA"
      conditions += "AND en_blanco='1' AND anulada='0'" if @form.estado == "EN_BLANCO"
      conditions += "AND en_blanco='0' AND anulada='0' AND cobrada='1'" if @form.estado == "COBRADA"
      conditions += "AND en_blanco='0' AND anulada='0' AND cobrada='0'" if @form.estado == "POR_COBRAR"
      
      conditions += get_condition_for_form_date_range(@form.start_month_emision, @form.start_year_emision, @form.end_month_emision, @form.end_year_emision, "fecha_emision")
      
      conditions += get_condition_for_form_date_range(@form.start_month_recepcion, @form.start_year_recepcion, @form.end_month_recepcion, @form.end_year_recepcion, "fecha_recepcion")
      
      conditions += get_condition_for_form_date_range(@form.start_month_cobranza, @form.start_year_cobranza, @form.end_month_cobranza, @form.end_year_cobranza, "fecha_cobranza")
      
      if @form.recepcion == "0"
        conditions += " AND fecha_recepcion IS NULL"
      end
      
      if @form.recepcion == "1"
        conditions += " AND fecha_recepcion IS NOT NULL"
      end
    end
    
    pre_sql = "FROM facturas WHERE tipo='#{@type}' #{conditions}"
    
    if @show_all
      limit_offset = ""
    else
      # Find out the total number of items found
      sql   = "SELECT COUNT(facturas.id) AS total " + pre_sql
      total = GuiaDeRemision.find_by_sql(sql)[0].total.to_i
      
      # Pages, dude
      @total_pages = (total / 25).ceil + 1
      @page        = session[:panel_page][current_tab] || 1
      @page        = @total_pages if @page > @total_pages
      limit_offset = " LIMIT 25 OFFSET " + ((@page - 1) * 25).to_s
    end
    
    @docs = Factura.find_by_sql "SELECT * #{pre_sql} ORDER BY empresa, numero DESC #{limit_offset}";
    
    render :action => "panel_facturas_boletas"
  end
  
  
  def set_facturas_page
    p = params[:page].to_i
    p = 1 if p <= 0
    
    session[:panel_page][params[:tab]] = p
    
    redirect_to :action => params[:tab]
  end
 

  def guias
    set_current_tab "guias"
    @tab       = "guias"
    @form      = Fionna.new "guias"
    conditions = ""
    
    set_companies_for @form
    
    reset_filter(@tab) if params[:reset_filters]
    set_filter(@tab, params) if params[:q]
    
    @form.load_values get_filter(@tab)
    
    if params[:account] && params[:account][:name]
      @form.client = params[:account][:name]
    end
    
    # Show all?
    if params[:show_all]
      @show_all = true
    else
      @show_all = false
    end
    
    if @form.valid?
      if @form.empresa_vendedora != "-1" && can_see_company?(@form.empresa_vendedora)
        conditions += "AND empresa='#{@form.empresa_vendedora}'"
      else
        conditions += "AND empresa IN #{companies_sql_list}"
      end
      
      unless @form.serie == "-1"
        conditions += "AND serie='#{@form.serie}'"
      end
      
      unless @form.month_retorno == "-1"
        conditions += " AND MONTH(fecha_retorno)='#{@form.month_retorno}'"
      end
      
      unless @form.year_retorno == "-1"
        conditions += " AND YEAR(fecha_retorno)='#{@form.year_retorno}'"
      end
      
      unless @form.month_emision == "-1"
        conditions += " AND MONTH(fecha_emision)='#{@form.month_emision}'"
      end
      
      unless @form.year_emision == "-1"
        conditions += " AND YEAR(fecha_emision)='#{@form.year_emision}'"
      end
      
      if @form.no_date == "1"
        conditions += " AND fecha_retorno IS NULL AND anulada='0'"
      end
      
      if @form.client != ""
        a = Account.search(@form.client).id
        conditions += " AND account_id='#{a}'"
      end
    end
    
    pre_sql = "FROM guias_de_remisiones WHERE 1=1 #{conditions}"

    if @show_all
      limit_offset = ""
    else
      # Find out the total number of items found
      sql   = "SELECT COUNT(guias_de_remisiones.id) AS total " + pre_sql
      total = GuiaDeRemision.find_by_sql(sql)[0].total.to_i
      
      # Pages, dude
      @total_pages = (total / 25).ceil + 1
      @page        = session[:panel_page]["guias"] || 1
      @page        = @total_pages if @page > @total_pages
      limit_offset = " LIMIT 25 OFFSET " + ((@page - 1) * 25).to_s
    end
    
    @guias = GuiaDeRemision.find_by_sql "SELECT * #{pre_sql} ORDER BY empresa, serie, numero DESC #{limit_offset}"
  end
  
  
  def set_guias_page
    p = params[:page].to_i
    p = 1 if p <= 0
    
    session[:panel_page]["guias"] = p
    
    redirect_to :action => "guias"
  end
  
  
  def order_facturation
    set_current_tab "orders"
    @form = Fionna.new "order_facturation"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        if @form.monto_adelanto == ""
          monto = 0.00
        else
          monto = @form.monto_adelanto
        end
        
        @project.monto_adelanto        = monto
        @project.dias_plazo            = @form.dias_plazo
        @project.cancelado_sin_factura = @form.cancelado
        @project.save
        
        @project.update_adelanto_status
        
        redirect_to :action => "order_facturation", :id => @project.orden_id
      end
    else
      @form.monto_adelanto = "%0.2f" % @project.monto_adelanto if !@project.monto_adelanto.nil? && @project.monto_adelanto > 0
      @form.cancelado      = @project.cancelado_sin_factura
      @form.dias_plazo     = @project.dias_plazo.to_s
    end
  end
  
  
  def order_facturas
    get_facturation_document_type
    set_current_tab "orders"
    
    if @type == "f"
      @ofs = @project.facturas
    else
      @ofs = @project.boletas
    end
  end
  
  
  def new_factura_1
    get_facturation_document_type
    
    if params[:fid]
      @factura = Factura.find params[:fid]
    end
    
    @form     = Fionna.new "new_factura_1"
    @searched = false
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        oid = @form.order
        
        @searched = true
        
        begin
          @order = Proyecto.find_odt oid
        rescue
        end
        
        @order_found = !@order.nil?
      end
    end
  end
  
  
  def new_factura_2
    get_facturation_document_type
    empresa = @project.empresa_vendedora
    
    @curr = FacturaNumber.peek_next(@type, empresa)
    @numbers = Factura.find_usable_for_new(@type, empresa)
    
    if request.post?
      if params[:reserve]
        FacturaNumber.reserve_next_as_blank(@type, empresa)
        redirect_to :action => "new_factura_2", :type => @type, :id => @project.orden_id
      end
      
      if params[:use_current]
        redirect_to :action => "new_factura_3", :type => @type, :id => @project.orden_id, :fid => @curr
      end
      
      if params[:use_from_list]
        fid = params[:fid].to_i
        
        if Factura.exists_for fid, @project.id, @type
        # He's trying to use this Factura for this ODT when he already had
          @repeated_error = true
        elsif @numbers.include? fid
          redirect_to :action => "new_factura_3", :type => @type, :id => @project.orden_id, :fid => fid
        end
      end
    end
  end
  
  
  def new_factura_3
    get_facturation_document_type
    empresa = @project.empresa_vendedora
    
    if params[:add]
      # We are adding an ODT to an existing Factura. Let's load the Factura!
      begin
        @factura = Factura.find params[:fid]
        @number  = @factura.numero
        @type    = @factura.tipo
        @adding  = true
      rescue
        redirect_to :controller => "dashboard", :action => "index"
      end
      
      unless @factura.can_be_added_this_project? @project
        redirect_to :action => "facturas"
      end
    else
      @number = params[:fid].to_i
      
      unless (FacturaNumber.available_for_new?(@number, @type, empresa))
        redirect_to :action => "facturas"
      end
      
      # Everything seems to be fine! Keep on.
      
      # Are we adding something to an existing Factura or are we creating
      # a new one from scratch?
      @factura  = Factura.find_by_numero_and_tipo_and_empresa @number, @type, empresa
    end
      
    if @factura
      @creating = false
      @ofs      = @factura.of
      @account  = @factura.account
    else
      @creating = true
      @ofs      = []
    end
    
    @form = Fionna.new "new_factura_3"
    
    related_accounts = get_options_list_for_project_related_accounts
    @form.set_property_of "razon_social", "options" => related_accounts
    
    if request.post?
      @form.load_values params
      
      if !@creating && @factura.moneda != @project.moneda_odt
        @form.set_property_of "tipo_de_cambio", { "mandatory" => true }
      end
      
      if @adding
        @form.set_property_of "razon_social", { "mandatory" => false }
        @form.razon_social = "-1"
      end
      
      # Details
      @details = multirow_load("factura_detalle", :descripcion, :cantidad, :valor_unitario)
     
      all_fine = true
      
      # Presion� alguno de los botones ya para validar toda la Factura?
      if (params[:n] || params[:c] || params[:g])
        monto = 0.00
        
        if @form.con_una_sola_descripcion == "1"
          # Only one description
          [:one_descripcion, :one_cantidad, :monto_odt].each do |f|
            @form.set_property_of f, { "mandatory" => true }
          end
          details_valid = true
        else
          # Multiple descriptions
          # The details, are they valid?
          details_valid = multirow_validate(@details)
          
          if details_valid
            @details.each do |d|
              monto += (d.cantidad.to_f * d.valor_unitario.to_f)
            end
            
            monto = monto.round2
          end
        end
        
        if @form.valid?
          if @form.con_una_sola_descripcion == "1"
            monto = @form.monto_odt.to_f
          end
          
          # Calculate if the amount we are invoicing is bigger than the
          # ODT's amount. We need to keep care of the currency change.
          unless @form.moneda == @project.moneda_odt
            tc = @form.tipo_de_cambio.to_f
            
            if @form.moneda == "S"
              monto = (monto / tc).round2
            else
              monto = (monto * tc).round2
            end
          end
          
          if monto > @project.facturated_remainder
            @monto = monto
            @wrong_amount = true
            all_fine = false
          end
        else
          all_fine = false
        end
        
        # Tipo de Cambio must oscillate on the range of +/- 10% of the
        # current TC
        unless @form.tipo_de_cambio == ""
          factura_tc = @form.tipo_de_cambio.to_f
          project_tc = @project.tipo_de_cambio
          percent    = project_tc * 0.10 # That's 10%
          range_up   = project_tc + percent
          range_dn   = project_tc - percent
          
          unless (factura_tc <= range_up) && (factura_tc >= range_dn)
            @form.set_error_msg_of :tipo_de_cambio, "Tipo de Cambio errado, confirme"
            all_fine = false
          end
        end
        
        # Yay!
        if all_fine && details_valid
          values = @form.get_values
          
          if @creating
            f = Factura.new
            
            a = Account.find values['razon_social']
            
            f.account_id = a.id
            
            f.factura_direccion_fiscal = a.extras.factura_direccion_fiscal
            
            if @project.factura_account_id.nil?
              f.razon_social = @project.factura_razon_social
              f.ruc          = @project.factura_ruc
            end
          else
            f = @factura
            
            if @adding
              # We want the Account of the "parent" Factura
              f.account_id   = @factura.account_id
              f.razon_social = @factura.razon_social
              f.ruc          = @factura.ruc
            else
              if @project.factura_account_id.nil?
                f.razon_social = @project.factura_razon_social
                f.ruc          = @project.factura_ruc
              else
                f.account_id   = values['razon_social']
                f.razon_social = nil
                f.ruc          = nil
              end
            end
          end
          
          if @form.con_una_sola_descripcion == "1"
            d =  Fionna.new("factura_detalle")
            d.descripcion    = @form.one_descripcion
            d.cantidad       = @form.one_cantidad
            d.valor_unitario = 0.00
            
            @details = [d]
          end
          
          
          values['fecha_emision'] = @form.process_textdate :fecha_emision
          
          f.numero         = @number
          f.tipo           = @type
          f.empresa        = empresa
          f.anulada        = false
          f.en_blanco      = false
          f.cobrada        = false
          f.confirmada     = false
          f.cargo_cobranza = false
          f.modalidad_pago = ''
          
          values.delete 'razon_social'
          values.delete 'descripcion'
          values.delete 'cantidad'
          values.delete 'valor_unitario'
          values.delete 'one_descripcion'
          values.delete 'one_cantidad'
          values.delete 'one_valor_unitario'
          values.delete 'monto_odt'
          
          # If he pressed the button to Accept and add another ODT, we change
          # the value of Completa as false
          if params[:c]
            values['completa'] = false
          # No, but if he pressed the Accept and add Guias, we change the
          # value of Completa to true
          elsif params[:g]
            values['completa'] = true
          end
          
          f.update_attributes values
          f.save
          
          if @creating
            FacturaNumber.get_next(@type, empresa)
          end
          
          # Details!
          f.update_details(@details, @project)
          
          of             = OrdenesFacturas.new
          of.proyecto_id = @project.id
          of.factura_id  = f.id
          # The monto is saved in the currency of the Project
          of.monto_odt   = monto
          of.moneda_odt  = @project.moneda_odt
          of.save
          
          # We save the Factura again, because we want to update its amount
          # with the now saved OrdenesFacturas. Kinda hacky. FIXME
          f.save 
          
          @project.update_adelanto_status
          
          if f.con_una_sola_descripcion?
            f.details.first.valor_unitario = (f.monto / f.details.first.cantidad)
            f.details.first.save
          end
          
          @project.save
          
          # Redirect according to teh button
          if params[:c]
            redirect_to :action => "new_factura_1", :fid => f.id, :type => @type
          elsif params[:g]
            redirect_to :action => "factura_add_guias", :type => "f", :fid => f.id
          else
            if @type == "f"
              redirect_to :action => "print_factura", :fid => f.id
#              redirect_to :action => "facturas", :fid => f.id, :type => "f", :from => "f"
            else
              redirect_to :action => "boletas", :fid => f.id, :type => "b", :from => "b"
            end
          end
        end
      end
    else
      # GET!
      
      # The Details! We prefill them with either the marked Cotization's data
      # or the ODT's. Let's see.
      
      if cotization = @project.marked_cotization
        @details = []
        
        cotization.details.each do |cd|
          f = Fionna.new("factura_detalle")
          
          f.descripcion    = cd.nombre
          f.cantidad       = cd.cantidad
          f.valor_unitario = "%0.2f" % cd.precio
          
          @details << f
        end
        
        @form.moneda = cotization.moneda
      else
        # We prefill the details with the ones of the ODT
        f = Fionna.new("factura_detalle")
        
        f.descripcion    = @project.nombre_proyecto
        f.cantidad       = "1"
        f.valor_unitario = "%0.2f" % @project.facturated_remainder
        
        @details = [f]
        
        @form.moneda = @project.moneda_odt
      end
      
      if @creating || (!@creating && @factura.en_blanco?)
        @form.razon_social   = @project.factura_account_id
        
        # If the account is not related, we auto-relate it
        unless related_accounts.keys.include? @form.razon_social
          ra = RelatedAccount.new({
            :account_id => @project.account_id,
            :related_id => @form.razon_social
          })
          ra.save
          
          # We need to reload the list... ugh, there's a duplication
          # here with the code above. FIXME
          related_accounts = get_options_list_for_project_related_accounts
          @form.set_property_of "razon_social", "options" => related_accounts
        end
        
        @form.descripcion    = @project.factura_descripcion
        @form.fecha_emision  = Time.now.strftime("%d/%m/%y")
        @form.tipo_de_cambio = "%0.2f" % TipoDeCambio.for_today.to_s
      else
        @form.load_values @factura.attributes
        @form.descripcion     = @ofs.first.descripcion
        @form.tipo_de_cambio  = "%0.2f" % @factura.tipo_de_cambio unless @factura.tipo_de_cambio.nil?
        @form.fecha_emision   = @factura.fecha_emision.strftime("%d/%m/%y") unless @factura.fecha_emision.nil?
        
        if @factura.con_una_sola_descripcion?
          @form.one_descripcion    = @factura.details.first.descripcion
          @form.one_cantidad       = @factura.details.first.cantidad
          @form.monto_odt          = "%0.2f" % @project.facturated_remainder
        end
      end
    end
  end
  
  
  def edit_factura
    @form    = Fionna.new "edit_factura"
    
    @details = []
    @factura.details.each do |d|
      fd = Fionna.new("factura_detalle")
      fd.descripcion    = d.descripcion
      fd.cantidad       = d.cantidad
      fd.valor_unitario = d.valor_unitario
      @details << fd
    end
    
    if @factura.anulada? || @factura.en_blanco?
      redirect_to :action => "facturas"
    end
    
    if request.post?
      @form.load_values params
      
      # Details
      @details = multirow_load("factura_detalle_edit", :descripcion)
      
      if params[:s] || params[:c]
        # Now, the details, are they valid?
        details_valid = multirow_validate(@details)
        
        if @form.valid? && details_valid
          values  = @form.get_values
          
          values['fecha_emision'] = @form.process_textdate :fecha_emision
          
          @factura.completa = false if params[:c]
          
          values.delete "descripcion"
          values.delete "cantidad"
          values.delete "valor_unitario"
          
          @factura.update_attributes values
          @factura.save
          
          # Update the details.
          @details.each_with_index do |d, i|
            @factura.details[i].descripcion = d.descripcion
            @factura.details[i].save
          end
          
          if params[:c]
            redirect_to :action => "new_factura_1", :fid => @factura.id, :type => @type
          else
            redirect_to :action => "show_factura", :fid => @factura.id, :type => @type, :from => "f"
          end
        end
      end
    else
      @form.load_values @factura.attributes
      
      @form.fecha_emision   = @factura.fecha_emision.strftime "%d/%m/%y" unless @factura.fecha_emision.nil?
      @form.tipo_de_cambio  = "%0.2f" % @factura.tipo_de_cambio unless @factura.tipo_de_cambio.nil?
    end
  end
  
  
  def show_factura
    get_comes_from
    
    @of               = @factura.of
    @fechas_probables = @factura.fechas_probables
    
    if @factura.account.nil?
      @contacto = nil
    else
      @contacto = @factura.account.contacto_cobranza || ContactoCobranza.new({ :account_id => @factura.account.id })
    end
    
    unless @factura.cobrada?
      @form  = Fionna.new "show_factura_a"
      @formb = Fionna.new "show_factura_b"
      
      # Form A
      if request.post? && params[:a]
        @form.load_values params
        
        if @form.valid?
          if @form.fecha_recepcion == ""
            fecha_recepcion = nil
          else
            fecha_recepcion = @form.process_textdate :fecha_recepcion
          end
          
          old_fecha_recepcion = @factura.fecha_recepcion
          
          @factura.fecha_recepcion = fecha_recepcion
          @factura.confirmada      = @form.confirmada
          @factura.modalidad_pago  = @form.modalidad_pago
          @factura.save
          
          @factura.reload
          
          if old_fecha_recepcion.nil? || old_fecha_recepcion.strftime("%y%m%d") != fecha_recepcion.strftime("%y%m%d")
            fp = FechaProbable.new({
              :factura_id    => @factura.id,
              :fecha         => @factura.proposed_charge_date,
              :observaciones => "Definida por Fecha de Recepcion"
            })
            fp.save
          end
          
          redirect_to :action => "show_factura", :fid => @factura.id, :from => @params[:from]
        end
      else # GET Form A
        if @factura.fecha_recepcion.nil?
          fecha_recepcion = ""
        else
          fecha_recepcion = @factura.fecha_recepcion.strftime "%d/%m/%y"
        end
        
        @form.fecha_recepcion = fecha_recepcion
        @form.confirmada      = @factura.confirmada
        @form.modalidad_pago  = @factura.modalidad_pago
      end
      
      # Form B
      
      # Form C
      unless @factura.fecha_recepcion.nil?
        if request.post? && params[:b]
          @formb.load_values params
          
          if @formb.valid?
            if @formb.fecha_probable == ""
              fecha_probable = nil
            else
              fecha_probable = @formb.process_textdate :fecha_probable
            end
            
            fp = FechaProbable.new({
              :factura_id    => @factura.id,
              :fecha         => fecha_probable,
              :observaciones => @formb.observaciones
            })
            fp.save
            
            redirect_to :action => "show_factura", :fid => @factura.id, :from => @params[:from]
          end
        else # GET Form C
          fp = @factura.current_fecha_probable
          
          if fp.nil?
            @formb.fecha_probable = ""
            @formb.observaciones  = ""
          else
            if fp.fecha
              @formb.fecha_probable = fp.fecha.strftime "%d/%m/%y"
            else
              @formb.fecha_probable = nil
            end
            @formb.observaciones  = fp.observaciones
          end
        end
      end
      
      # Form D
      if @contacto
        if validate_billing_contact_form
          redirect_to :action => "show_factura", :fid => @factura.id
        end
      end
    end
  end
  
  
  def void_factura
    @form = Fionna.new "void_factura"
    
    if request.post?
      @form.load_values params
      @form.empresa = @factura.empresa.to_s
      
      if @form.valid?
        @factura.anulada = true
        @factura.save
        
        @factura.of.each do |o|
          o.proyecto.update_adelanto_status
          o.proyecto.save
        end
        
        redirect_to :action => "facturas"
      end
    end
  end
  
  
  def blank_factura
    @form = Fionna.new "blank_factura"
    
    if request.post?
      @form.load_values params
      @form.empresa = @factura.empresa.to_s
      
      if @form.valid?
        @factura.blank!
        redirect_to :action => "facturas"
      end
    end
  end
  
  
  def order_guias
    set_current_tab "orders"
    
    @project = Proyecto.find_odt params[:id]
    @guias   = @project.active_guias
    @id      = @project.orden_id
  end
  
  
  def new_guia_1
    set_current_tab "guias"
    
    @form     = Fionna.new "new_guia_1"
    @searched = false
    
    if params[:order]
      @form.load_values params
      
      if @form.valid?
        oid = @form.order
        
        @searched = true
        
        begin
          @order       = Proyecto.find_odt oid
          @order_found = true
        rescue ActiveRecord::RecordNotFound
          @order_found = false
        end
      end
    end
  end
  
  
  def new_guia_2
    set_current_tab "guias"
    
    raise "This Order can't have Guias" unless @project.can_have_guias? # FIXME
    
    @empresa = @project.empresa_vendedora
    
    if @project.tipo_nuevo_proyecto?
      @serie = "1"
    else
      @serie = params[:serie]
    end
    
    @curr        = GuiaNumber.peek_next(@serie, @empresa)
    @blank_guias = GuiaDeRemision.find_usable_for_new(@serie, @empresa)
    
    if request.post?
      if params[:reserve]
        GuiaNumber.reserve_next_as_blank(@serie, @empresa)
        redirect_to :action => "new_guia_2", :id => @project.orden_id, :fid => @date.id
      end
      
      if params[:use_current]
        redirect_to :action => "new_guia_3", :id => @project.orden_id, :serie => @serie, :number => @curr
      end
      
      if params[:use_from_list]
        gid = params[:gid].to_i
        g   = GuiaDeRemision.find gid
        
        raise "Non blank Guia can't be used as new record" unless g.en_blanco?
        
        redirect_to :action => "new_guia_3", :id => @project.orden_id, :serie => @serie, :number => g.numero
      end
    end
  end
  
  
  def new_guia_3
    set_current_tab "guias"
    
    # RAISE if guia doesn't match empresa of ODT
    # If the number is the same of an existing Guia and it is blank, it is
    # because we want to overwrite that guia
    raise "This Order can't have Guias" unless @project.can_have_guias? # FIXME
    
    @serie = params[:serie]
    raise "Order type (\"New Project\") mismatchs Series" if @project.tipo_nuevo_proyecto? && @serie != "1"
    
    @number = params[:number]
    empresa = @project.empresa_vendedora
    @form   = Fionna.new "new_guia_3"
    
    # We search for a Guia with this same series and number and empresa.
    # If it's blank, then we're going to overwrite it!
    
    # Details
    @details = []
    @fechas  = @project.fechas_de_entrega.select { |f| f.quantity_available_for_guia > 0 }
    
    @fechas.each do |f|
      if f.quantity_available_for_guia > 0
        fd = Fionna.new "guia_detalle"
        fd.descripcion = f.detalle
        fd.cantidad    = ""
        
        @details << fd
      end
    end
    
    if request.post?
      @form.load_values params
      
      @details = multirow_load("guia_detalle", :descripcion, :cantidad, :medida)
      
      active_details = 0
      
      @details.each do |d|
        if d.cantidad != ""
          d.set_property_of "descripcion", { "mandatory" => true }
          d.set_property_of "cantidad",    { "mandatory" => true }
          d.set_property_of "medida",      { "mandatory" => true }
          active_details += 1
        end
      end
      
      # The ajaxy thing special case
      if params[:account] && params[:account][:name]
        @form.razon_social = params[:account][:name]
      end
      
      if @form.ultima_guia == "1"
        @form.set_property_of "fecha_despacho", { "mandatory" => true }
      end
      
      if params[:go]
        form_valid    = @form.valid?
        details_valid = multirow_validate(@details)
      end
      
      if active_details == 0
        details_valid        = false
        @empty_details_error = true
      end
      
      if details_valid
        # Can't exceed the available in plant
        @details.each_with_index do |d, i|
          if d.cantidad.to_i > @fechas[i].quantity_available_for_guia
            d.set_error_msg_of "cantidad", "No puede exceder la cantidad disponible (#{@fechas[i].quantity_available_for_guia})"
            details_valid = false
          end
        end
      end
      
      # This is it
      if details_valid && form_valid
        values = @form.get_values
        
        values['fecha_emision']  = @form.process_textdate :fecha_emision
        values['fecha_despacho'] = @form.process_textdate :fecha_despacho
        values['fecha_retorno']  = @form.process_textdate :fecha_retorno
        
        values['account_id'] = Account.search(@form.razon_social).id
        values.delete 'razon_social'
        
        # Only one Guia can be the ultima_guia for this ODT
        values['ultima_guia'] = "0" if @project.con_guias_completas?
        
        # Is the number ok?
        yes_its_ok  = false
        using_blank = false
        
        n = GuiaNumber.peek_next(@serie, empresa)
        
        if @number.to_i == n
          GuiaNumber.get_next(@serie, empresa)
          
          yes_its_ok = true
          r          = GuiaDeRemision.new
        else
          # Perhaps it is referring a blank Guia
          r = GuiaDeRemision.find_by_serie_and_numero_and_empresa @serie, @number, empresa
          
          if r && r.en_blanco?
            yes_its_ok  = true
            using_blank = true
            
            r.blank!
          end
        end
        
        raise "Invalid Guia Number" unless yes_its_ok
        
        r.attributes          = values
        r.numero              = @number
        r.empresa             = empresa
        r.serie               = @serie
        r.proyecto_id         = @project.id
        r.anulada             = false
        r.en_blanco           = false
        r.save
        
        # Now, the details!
        @details.each_with_index do |d, i|
          if d.cantidad != ""
            nd = GuiaDetalle.new(d.get_values)
            nd.guia_de_remision_id = r.id
            nd.fechas_de_entrega_id = @fechas[i].id
            nd.save
          end
        end
        
        redirect_to :action => "order_guias", :id => @project.orden_id
      end
    else
      @form.razon_social = @project.factura_razon_social
    end
  end
  
  
  def edit_guia
    set_current_tab "guias"
    
    @project = @guia.proyecto
    
    @form = Fionna.new "edit_guia"
    @details = []
    
    @guia.detalles.each do |d|
      fd = Fionna.new "guia_detalle"
      fd.descripcion = d.descripcion
      fd.cantidad    = d.cantidad.to_s
      fd.medida      = d.medida
      
      fd.set_property_of "descripcion", { "mandatory" => true }
      fd.set_property_of "cantidad",    { "mandatory" => true }
      fd.set_property_of "medida",      { "mandatory" => true }
      
      @details << fd
    end
    
    if request.post?
      @form.load_values params
      
      if @form.ultima_guia == "1"
        @form.set_property_of "fecha_despacho", { "mandatory" => true }
      end
      
      @details = multirow_load("guia_detalle", :descripcion, :cantidad, :medida)
      
      # The ajaxy thing special case
      if params[:account] && params[:account][:name]
        @form.razon_social = params[:account][:name]
      end
      
      if params[:go]
        form_valid    = @form.valid?
        details_valid = multirow_validate(@details)
      end
      
      if details_valid
        # Can't exceed the available in plant, can't be zero
        @details.each_with_index do |d, i|
          qty = @guia.detalles[i].quantity_available_from_plant_when_editing
          
          if d.cantidad.to_i == 0
            d.set_error_msg_of "cantidad", "Cantidad no puede ser cero"
            details_valid = false
          
          elsif d.cantidad.to_i > qty
            d.set_error_msg_of "cantidad", "No puede exceder la cantidad disponible (#{qty})"
            details_valid = false
          end
        end
      end
      
      if details_valid && form_valid
        values = @form.get_values
        
        values['fecha_emision']  = @form.process_textdate :fecha_emision
        values['fecha_despacho'] = @form.process_textdate :fecha_despacho
        values['fecha_retorno']  = @form.process_textdate :fecha_retorno
        
        values['account_id'] = Account.search(@form.razon_social).id
        values.delete 'razon_social'
        
        # Only one Guia can be the ultima_guia for this ODT
        unless @project.last_guia == @guia
          values['ultima_guia'] = "0" if @project.con_guias_completas?
        end
        
        @guia.attributes = values
        @guia.save
        
        # Now, the details!
        @guia.detalles.each_with_index do |d, i|
          d.attributes = @details[i].get_values
          d.save
        end
        
        redirect_to :action => "guias"
      end
    else
      @form.load_values @guia.attributes
      
      @form.fecha_emision  = @guia.fecha_emision.strftime "%d/%m/%y"
      @form.fecha_despacho = @guia.fecha_despacho.strftime "%d/%m/%y" unless @guia.fecha_despacho.nil?
      @form.fecha_retorno  = @guia.fecha_retorno.strftime "%d/%m/%y" unless @guia.fecha_retorno.nil?
      
      unless @guia.account.nil?
        @form.razon_social = @guia.account.name
      end
    end
  end
  
  
  def show_guia
    redirect_to(:action => "edit_guia", :id => params[:id]) if @guia.proyecto.nil? && !@guia.en_blanco?
  end
  
  
  def void_guia
    @form = Fionna.new "void_guia"
    
    if request.post?
      @form.load_values params
      @form.empresa = @guia.empresa.to_s
      
      if @form.valid?
        @guia.anulada = true
        @guia.save
        
        redirect_to :action => "guias"
      end
    end
  end
  
  
  def delete_of
    of = OrdenesFacturas.find params[:id]
    
    project = of.proyecto
    factura = of.factura
    
    # You can't delete this if it is the last OF of this Factura
    unless factura.of.size == 1
      of.destroy
      
      # Update each other's stuff
      project.update_adelanto_status
      factura.save
    end
    
    redirect_to :action => "show_factura", :fid => factura.id, :type => factura.tipo, :from => factura.tipo.downcase
  end
  
  
  def factura_guias
    @fgs = @factura.fg
  end
  
  
  def factura_add_guias
    @ofs = @factura.of
    
    if request.post?
      # Delete all guias
      unless params[:selection].nil?
        selection = params[:selection]
        
        FacturaGuia.delete_all_for @factura
        
        selection.each do |gid|
          fg = FacturaGuia.new({
            :factura_id          => @factura.id,
            :guia_de_remision_id => gid
          })
          fg.save
        end
      end
      
      redirect_to :action => "factura_guias", :fid => @factura.id, :type => @factura.tipo
    end
  end
  
  
  def check_if_processable
    if @project.tipo_proyecto != T_NUEVO_PROYECTO || @project.anulado? # || !@project.facturation_data_complete?
      redirect_to :action => "non_factura", :id => @project.orden_id
      return false
    end
  end
  
  
  def cannot_access_if_printed
    if @factura.imprimida?
      redirect_to :action => "show_factura", :type => @factura.tipo, :from => @factura.tipo, :fid => @factura.id
      return false
    end
  end
  
  
  def get_comes_from
    @from = params[:from]
    
    if @from == "f"
      set_current_tab "facturas" if @type == "f"
      set_current_tab "boletas" if @type == "b"
    elsif @from == "o"
      set_current_tab "orders"
    elsif @from == "g"
      set_current_tab "guias"
    elsif @from == "c"
      set_current_tab "billing"
    end
  end
  
  
  def auto_complete_for_account_name
    super_auto_complete_for_account_name
  end
  
  
  def get_options_list_for_project_related_accounts
    accts = [@project.account] + @project.account.related_accounts
    
    r = OHash.new
    r["-1"] = "[Elegir]"
    accts.each do |a|
      r[a.id] = a.name
    end
    
    return r
  end
  
  
  def billing
    set_current_tab "billing"
    
    @docs = []
    docs  = Factura.find_by_sql "SELECT * FROM facturas WHERE anulada='0' AND en_blanco='0' AND cobrada='0' AND cargo_cobranza='1' AND empresa IN #{companies_sql_list}"
    
    docs.each do |f|
      if f.of[0].nil?
        executive = ""
      else
        executive = f.of[0].proyecto.executive.full_name
      end
      
      # Dias Vencidos
      if !f.proposed_charge_date.nil? && f.proposed_charge_date < Time.today
        dias_vencidos = ((Time.today - f.proposed_charge_date) / (60*60*24)).round
      else
        dias_vencidos = ""
      end
      
      s               = OpenStruct.new
      s.factura_id    = f.id
      s.factura_tipo  = f. tipo
      s.odts          = f.list_of_odts
      s.cliente       = f.razon_social
      s.femision      = f.fecha_emision
      s.frecepcion    = f.fecha_recepcion
      s.cond_pago     = f.dias_plazo
      s.fpago         = f.proposed_charge_date
      s.dias_vencidos = dias_vencidos
      s.fprobable     = nil 
      s.observaciones = ""
      s.no_factura    = f.formatted_factura_number
      s.dolares       = f.monto_as_dollars
      s.soles         = f.monto_as_soles
      s.ejecutivo     = executive
      
      @docs << s
    end
    
    # Teh sort!
    sort_field = session[:billing_sort] || "cliente"
    sort_field = "cliente" unless @docs.first.methods.include? sort_field
    
    @docs = @docs.sort do |x, y|
      rx = x.send sort_field
      ry = y.send sort_field
      
      if ["femision", "frecepcion", "fpago", "fprobable"].include? sort_field
        rx = 100.years.ago if rx.nil?
        ry = 100.years.ago if ry.nil?
      end
      
      if sort_field == "dias_vencidos"
        rx = 0 if rx == ""
        ry = 0 if ry == ""
      end
      
      rx <=> ry
    end
  end
  
  
  def set_billing_sort_field
    session[:billing_sort] = params[:field] || ""
    redirect_to :action => "billing"
  end
  
  
  def billing_panel
    set_current_tab "billing"
    @facturas_buffer = []
    
    def calculate(f, c, what)
      facturas = f
      cons     = c
      
      facturas.each do |f|
        aid = f.account_id || f.ruc
        
        cons[aid] ||= OpenStruct.new
        
        cons[aid].account_id   = aid
        cons[aid].account_name = f.razon_social
        
        cons[aid].docs ||= 0
        
        unless @facturas_buffer.include? f.id
          cons[aid].docs  += 1
          @facturas_buffer << f.id
        end
        
        cons[aid].fecha_pago ||= nil
        current                = cons[aid].fecha_pago
        
        if (!f.fecha_probable.nil? && !current.nil?) && (f.fecha_probable < current)
          fecha_pago = f.fecha_probable
        elsif !f.fecha_probable.nil?
          fecha_pago = f.fecha_probable
        else
          fecha_pago = current
        end
        
        cons[aid].fecha_pago = fecha_pago
        
        cons[aid].total_to_confirm ||= 0.00
        cons[aid].total_to_bill    ||= 0.00
        
        if what == :to_bill
          cons[aid].total_to_bill    += f.monto_as_dollars
        else
          cons[aid].total_to_confirm += f.monto_as_dollars
        end
      end
      
      return cons
    end
    
    @unconfirmed   = Factura.list_of_emitted_and_unconfirmed(companies_sql_list)
    @close_to_bill = Factura.close_to_bill_date(companies_sql_list)
    cons           = {}
    
    cons = calculate(@close_to_bill, cons, :to_bill)
    cons = calculate(@unconfirmed, cons, :to_confirm)
    
    @clients = []
    cons.each do |k, v|
      @clients << v
    end
    @clients = (@clients.sort_by { |a| a.total_to_bill }).reverse
  end
  
  
  def billing_panel_detail
    aid = params[:id]
    
    # The ID of the client can be an Account ID for new Facturas or
    # the RUC for the old formatted ones
    begin
      @account      = Account.find aid
      @account_name = @account.name
      @type         = :account
    rescue
      @account = nil
      @type    = :ruc
      
      f = Factura.find_by_ruc aid
      
      if f
        @account_name = f.razon_social
      else
        raise "BILLING PANEL DETAIL ERR"
      end
    end
    
    @form = Fionna.new "billing_panel_detail"
    
    if request.post?
      if params[:b] && params[:b].is_a?(HashWithIndifferentAccess)
        @blist = params[:b].keys
      else
        @blist = []
      end
      
      if params[:c] && params[:c].is_a?(HashWithIndifferentAccess)
        @clist = params[:c].keys
      else
        @clist = []
      end
      
      # Button to confirm Facturas
      if params[:mark_confirm]
        @clist.each do |fid|
          f = Factura.find fid
          f.confirmada = true
          f.save
        end
        redirect_to :action => "billing_panel_detail", :id => aid
      
      # Button to mark them as billed (yay!)
      elsif params[:mark_bill]
        @form.load_values params
        @form.set_property_of "fecha_cobranza", { "mandatory" => true }
        
        if @form.valid?
          @blist.each do |fid|
            f                = Factura.find fid
            f.cobrada        = true
            f.fecha_cobranza = @form.process_textdate "fecha_cobranza"
            f.save
          end
          redirect_to :action => "billing_panel_detail", :id => aid
        end
      
      # Button to update teh data
      else
        @form.load_values params
        
        if @form.fecha_probable != "" || @form.observaciones != ""
          @form.set_property_of "fecha_probable", { "mandatory" => true }
          @form.set_property_of "observaciones", { "mandatory" => true }
        end
        
        if @form.valid?
          new_attribs = {}
          list        = (@blist + @clist).uniq
          
          new_attribs["fecha_recepcion"] = @form.process_textdate :fecha_recepcion unless @form.fecha_recepcion == ""
          new_attribs["modalidad_pago"]  = @form.modalidad_pago unless @form.modalidad_pago == ""
          fecha_probable                 = @form.process_textdate :fecha_probable unless @form.fecha_probable == ""
          
          list.each do |fid|
            f = Factura.find fid
            f.update_attributes new_attribs
            f.save
            
            unless @form.fecha_probable == ""
              fp = FechaProbable.new
              fp.factura_id    = fid
              fp.fecha         = fecha_probable
              fp.observaciones = @form.observaciones
              fp.save
            end
          end
          
          redirect_to :action => "billing_panel_detail", :id => aid
        end
      end
    end
    
    @unconfirmed   = Factura.list_of_emitted_and_unconfirmed(companies_sql_list, aid, @type)
    @close_to_bill = Factura.close_to_bill_date(companies_sql_list, aid, @type)
  end
  
  
  def toggle_factura_confirmed
    f = Factura.find params[:id]
    f.confirmada = !f.confirmada?
    f.save
    
    true
    render :nothing => true
  end
  
  
  def edit_billing_contact
    id = params[:id]
    
    @account  = Account.find id
    @contacto = @account.contacto_cobranza || ContactoCobranza.new({ :account_id => @account.id })
    
    if validate_billing_contact_form
      redirect_to :action => "edit_billing_contact", :id => id
    else
      render :layout => "popup"
    end
  end
  
  
  def validate_billing_contact_form
    @form_bc = Fionna.new "billing_contact_form"
    
    if request.post? && params[:c]
      @form_bc.load_values params
      
      if @form_bc.valid?
        @contacto.update_attributes @form_bc.get_values
        @contacto.save
        
        return true
      end
    else
      @form_bc.load_values @contacto.attributes
    end
    
    return false
  end
  
  
  def messenger_list
    @deliver_list = Factura.to_be_delivered(companies_sql_list)
    @bill_list    = Factura.to_be_billed(companies_sql_list)
    @list         = []
    
    def calculate(data, cons, what)
      data.each do |f|
        id = f.razon_social
        
        unless f.account.nil?
          direccion = f.account.extras.factura_direccion
        else
          direccion = ""
        end
        
        cons[id]              ||= {}
        cons[id][:to_deliver] ||= []
        cons[id][:to_bill]    ||= []
        cons[id][:address]    ||= direccion
        
        cons[id][what] << f
      end
      
      return cons
    end
    
    cons  = {}
    cons  = calculate(@deliver_list, cons, :to_deliver)
    cons  = calculate(@bill_list, cons, :to_bill)
    
    @data = []
    
    cons.each do |k, v|
      r = OpenStruct.new
      r.razon_social = k
      r.address      = v[:address]
      r.to_deliver   = v[:to_deliver].sort_by { |f| f.numero }
      r.to_bill      = v[:to_bill].sort_by { |f| f.numero }
      
      @data << r
    end
    
    @data = @data.sort_by { |r| r.razon_social.downcase }
    
    render :layout => false
  end
  
  
  def load_invoices
    set_current_tab "billing"
    
    @form     = Fionna.new "load_invoices"
    @facturas = Factura.unloaded_invoices(companies_sql_list)
    
    if request.post? && params[:facturas].class == Array
      @form.load_values params
      @form.empresa = APOYO.to_s
      
      if @form.valid?
        params[:facturas].each do |fid|
          begin
            f = Factura.find fid
          rescue
            f = nil
          end
          
          if !f.nil? && f.loadable?
            f.cargo_cobranza       = true
            f.fecha_cargo_cobranza = Time.now
            f.save
          end
        end
        redirect_to :action => "load_invoices"
      end
    end
  end
  
  
  def load_history
    @form     = Fionna.new "load_history"
    
    @form.load_values params
    
    conditions = ""
    
    # The ajaxy thing special case
    if params[:account] && params[:account][:name]
      @form.client = params[:account][:name]
    end
    
    if params[:q] && @form.valid?
      unless @form.client == ""
        account_id = Account.search(@form.client).id
        conditions += "AND account_id='#{account_id}'"
      end
    end
    
    @facturas = Factura.find_by_sql("
      SELECT *
        FROM facturas
       WHERE cargo_cobranza='1'
         AND empresa IN #{companies_sql_list}
             #{conditions}
    ORDER BY fecha_cargo_cobranza DESC
    ")
  end
  
  
  def print_factura
    if request.post?
      # Mark Factura as printed
      @factura.imprimida = true
      @factura.save
      
      @factura.make_inmutable
      
      redirect_to :action => "show_factura", :type => @factura.tipo, :fid => @factura.id, :from => @factura.tipo
    end
  end
  
  
  def print_factura_preview
    if params[:preview]
      preview = true
    else
      preview = false
    end
    
    pdf_file = PDF_PATH + "preview_#{@factura.id}.pdf"
    
    if @factura.empresa == APOYO
      nombre        = @factura.razon_social.factura_format(48, 2)
      direccion     = @factura.direccion_fiscal.factura_format(101, 2)
      preview_image = "apoyo.jpg"
      
      pos_nombre    = [[87, 316], 290, 24]
      pos_ruc       = [[405, 316], 70, 12]
      pos_fecha     = [[510, 316], 70, 12]
      pos_address   = [[87, 298], 290, 24]
      pos_odt       = [[517, 298], 70, 24]
      pos_desc      = [[40, 257], 315, 140]
      pos_cant      = [[362, 257], 73, 140]
      pos_vu        = [[443, 257], 70, 140]
      pos_vv        = [[520, 257], 70, 140]
      pos_subtotal  = [[470, 87], 120, 12]
      pos_igv       = [[470, 68], 120, 12]
      pos_total     = [[470, 50], 120, 12]
      pos_total_s   = [[42, 115], 415, 24]
    
    elsif @factura.empresa == ARQUITECTURA
      nombre        = @factura.razon_social.factura_format(45, 1)
      direccion     = @factura.direccion_fiscal.factura_format(87, 1)
      preview_image = "arquitectura.jpg"
      
      pos_nombre    = [[89, 332], 274, 12]
      pos_ruc       = [[405, 332], 70, 12]
      pos_fecha     = [[515, 332], 70, 12]
      pos_address   = [[90, 315], 270, 24]
      pos_odt       = [[523, 318], 70, 24]
      pos_desc      = [[42, 273], 315, 140]
      pos_cant      = [[367, 273], 73, 140]
      pos_vu        = [[450, 273], 70, 140]
      pos_vv        = [[527, 273], 70, 140]
      pos_subtotal  = [[470, 102], 120, 12]
      pos_igv       = [[470, 82], 120, 12]
      pos_total     = [[470, 65], 120, 12]
      pos_total_s   = [[42, 132], 415, 24]
    end
    
    ruc       = @factura.ruc.factura_format(11, 1)
    fecha     = @factura.fecha_emision.strftime("%d/%m/%Y").factura_format(11, 1)
    
    # ODT numbers
    orders = []
    
    @factura.of.each do |o|
      orders << o.proyecto.orden_id
    end
    
    orders = orders.join(", ").factura_format(11, 1)
    
    subtotal = (currency(@factura.moneda) + " " + format_price(@factura.monto)).rjust(20, " ")
    igv      = (currency(@factura.moneda) + " " + format_price((@factura.monto * 0.19))).rjust(20, " ")
    total    = (currency(@factura.moneda) + " " + format_price((@factura.monto * 1.19))).rjust(20, " ")
    
    # Total in Words
    t        = (@factura.monto * 1.19).round2
    a        = t.truncate
    b        = (t - t.floor).round2 * 100
    total_s  = "SON " + a.to_words.upcase + " Y " + b.floor.to_s + "/100 " + (@factura.moneda == "S" ? "NUEVOS SOLES" : "DOLARES AMERICANOS") + "\nS. E. U. O."
    
    # Details!
    descripciones = []
    cantidades    = []
    valores       = []
    ventas        = []
    odt           = nil
    
    @factura.details.each do |d|
      if @factura.con_una_sola_descripcion?
        text = ""
      else
        if odt != d.proyecto.orden_id
          odt  = d.proyecto.orden_id
          text = "--- ODT #{odt} ---\n"
          
          cantidades << ""
          valores    << ""
          ventas     << ""
        else
          text = ""
        end
      end
      
      td = text + d.descripcion
      
      descripciones << td
      cantidades    << d.cantidad.to_s.factura_format(12, 1).rjust(12, " ")
      valores       << format_price(d.valor_unitario).factura_format(11, 1).rjust(11, " ")
      ventas        << format_price(d.valor_de_venta).factura_format(11, 1).rjust(11, " ")
      
      # How many empty lines should we leave for the other fields?
      c = td.split("\n").size - 2
      
      c.times do
        cantidades << ""
        valores    << ""
        ventas     << ""
      end
      
    end
    
    descripciones = descripciones.join("\n").factura_format(52, 11)
    cantidades    = cantidades.join("\n")
    valores       = valores.join("\n")
    ventas        = ventas.join("\n")
    
    
    # Ok gentlemen, let's generate the PDF
    pdf = Prawn::Document.new({
      :page_size     => "APOYO",
      :left_margin   => 0.0,
      :right_margin  => 0.0,
      :top_margin    => 0.0,
      :bottom_margin => 0.0
    })

    pdf.font PDF_FONT
    
    pdf.image PDF_PATH + preview_image, :position => :left, :vposition => :top, :width => 630 if preview

    # Nombre
    pdf.bounding_box(pos_nombre[0], :width => pos_nombre[1], :height => pos_nombre[2]) do
      pdf.text nombre, :size => PDF_FONT_SIZE
    end

    # RUC
    pdf.bounding_box(pos_ruc[0], :width => pos_ruc[1], :height => pos_ruc[2]) do
      pdf.text ruc, :size => PDF_FONT_SIZE
    end

    # Fecha
    pdf.bounding_box(pos_fecha[0], :width => pos_fecha[1], :height => pos_fecha[2]) do
      pdf.text fecha, :size => PDF_FONT_SIZE
    end

    # Address
    pdf.bounding_box(pos_address[0], :width => pos_address[1], :height => pos_address[2]) do
      pdf.text direccion, :size => PDF_FONT_SIZE
    end

    # ODT
    pdf.bounding_box(pos_odt[0], :width => pos_odt[1], :height => pos_odt[2]) do
      pdf.text orders, :size => PDF_FONT_SIZE
    end

    # Descripciones
    pdf.bounding_box(pos_desc[0], :width => pos_desc[1], :height => pos_desc[2]) do
      pdf.text descripciones, :size => PDF_FONT_SIZE
    end

    # Cantidades
    pdf.bounding_box(pos_cant[0], :width => pos_cant[1], :height => pos_cant[2]) do
      pdf.text cantidades, :size => PDF_FONT_SIZE
    end

    # Valor Unitario
    pdf.bounding_box(pos_vu[0], :width => pos_vu[1], :height => pos_vu[2]) do
      pdf.text valores, :size => PDF_FONT_SIZE
    end

    # Valor de Venta
    pdf.bounding_box(pos_vv[0], :width => pos_vv[1], :height => pos_vv[2]) do
      pdf.text ventas, :size => PDF_FONT_SIZE
    end
    
    
    # Sub Total
    pdf.bounding_box(pos_subtotal[0], :width => pos_subtotal[1], :height => pos_subtotal[2]) do
      pdf.text subtotal, :size => PDF_FONT_SIZE
    end

    # IGV
    pdf.bounding_box(pos_igv[0], :width => pos_igv[1], :height => pos_igv[2]) do
      pdf.text igv, :size => PDF_FONT_SIZE
    end

    # Total
    pdf.bounding_box(pos_total[0], :width => pos_total[1], :height => pos_total[2]) do
      pdf.text total, :size => PDF_FONT_SIZE
    end
    
    # Total in Words
    pdf.bounding_box(pos_total_s[0], :width => pos_total_s[1], :height => pos_total_s[2]) do
      pdf.text total_s, :size => PDF_FONT_SIZE
    end


    if pdf.page_count > 1
      puts "WARNING! More than one page rendered."
    end
    
    pdf.render_file pdf_file
    
    send_data(File.read(pdf_file),
      :filename    => "preview_#{@factura.id}.pdf",
      :type        => "application/pdf",
      :disposition => "inline"
    )
  end
end

