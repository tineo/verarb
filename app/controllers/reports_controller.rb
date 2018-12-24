class ReportsController < ApplicationController
  before_filter :set_tab_reports
  before_filter :check_access
  
  
  def ventas
    conditions = "proyectos.con_orden_de_trabajo='1' AND NOT #{SQL_VERA_DELETED} "
    
    # If he's not an admin, then we hardcode the user's username
    unless is_supervisor?
      conditions = conditions + " AND opportunities.assigned_user_id='" + session[:user][:id] + "'"
    end
    
    # Sort parameters default values
    params["sort_odt"]  = "0" unless params["sort_odt"]
    params["sort_exec"] = "0" unless params["sort_exec"]
    params["sort_cat"]  = "0" unless params["sort_cat"]
    params["dir_odt"]   = "0" unless params["dir_odt"]
    params["dir_exec"]  = "0" unless params["dir_exec"]
    params["dir_cat"]   = "0" unless params["dir_cat"]
    
    
    # Let's go with da form
    @form = Fionna.new "ventas_report"
    set_companies_for(@form, :no_unselected)
    
    @form.load_values params
    
    @odt_data  = []
    @exec_data = []
    @cat_data  = []
    @cat_total = 0
    
    unless params[:q] # That is, no form request yet
      @form.empresa_vendedora = session[:user][:companies].map { |c| c.to_s }
      
      @form.start_month = Time.now.month
      @form.start_year  = Time.now.year
      @form.end_month   = Time.now.month
      @form.end_year    = Time.now.year
    end
    
    if @form.valid?
      conditions += "AND opportunities.assigned_user_id='#{@form.executive}' " unless @form.executive == "-1"
      
      conditions += "AND proyectos.empresa_vendedora IN (" + @form.empresa_vendedora.join(", ") + ")"
      
      conditions += "AND proyectos.account_id='#{@form.client}' " unless @form.client == "-1"
      
      conditions += "AND proyectos.tipo_de_venta='#{@form.category}' " unless @form.category == "-1"
      
      conditions += "AND proyectos.tipo_proyecto='#{@form.project_type}' " unless @form.project_type == "-1"
      
      conditions += "AND proyectos.facturado='#{@form.facturada}' " unless @form.facturada == "-1"
      
      if @form.estado == "-1"
        conditions += "AND opportunities.sales_stage IN ('Closed Won', 'Closed Lost') " 
        if @form.estado.to_i == E_PERDIDO
          conditions += "AND opportunities.sales_stage='Closed Lost' AND proyectos.anulado='0' "
        elsif @form.estado.to_i == E_TERMINADO
          conditions += "AND opportunities.sales_stage='Closed Won' AND proyectos.anulado='0' "
        elsif @form.estado.to_i == E_ANULADO
          conditions += "AND proyectos.anulado='1' "
        end
      end
      
      # Start Date
      if (@form.start_day == "-1" && @form.start_month == "-1" && @form.start_year != "-1")
        # He chose only year and no month nor day, this means to consider
        # the start of the whole year
        start_date = Time.mktime(@form.start_year, 1, 1)
      elsif (@form.start_day == "-1" && @form.start_month != "-1" && @form.start_year != "-1")
        # He chose year and month
        start_date = Time.mktime(@form.start_year, @form.start_month, 1)
      elsif (@form.start_day != "-1" && @form.start_month != "-1" && @form.start_year != "-1")
        # He chose all three
        start_date = Time.mktime(@form.start_year, @form.start_month, @form.start_day)
      else
        # He chose some other thing which I can't think of
        start_date = false
      end
      
      # Now the End Date -- similar to Start Date, so read the comments above
      if (@form.start_day == "-1" && @form.end_month == "-1" && @form.end_year != "-1")
        end_date = Time.mktime(@form.end_year, 12, 31, 23, 59, 59)
      elsif (@form.start_day == "-1" && @form.end_month != "-1" && @form.end_year != "-1")
        # He chose year and month
        # The Date.civil thing is to find out the last day of the month.
        # Not so clever, and I don't like it that much, but works.
        end_date = Time.mktime(@form.end_year, @form.end_month, Date.civil(@form.end_year.to_i, @form.end_month.to_i, -1).day, 23, 59, 59)
      elsif (@form.end_day != "-1" && @form.end_month != "-1" && @form.end_year != "-1")
        end_date = Time.mktime(@form.end_year, @form.end_month, @form.end_day, 23, 59, 59)
      else
        end_date = false
      end
      
      start_date = start_date.strftime("%Y-%m-%d %H:%M:%S") if start_date
      end_date   = end_date.strftime("%Y-%m-%d %H:%M:%S") if end_date
      
      if start_date && end_date
        conditions += "AND fecha_creacion_odt BETWEEN '#{start_date}' AND '#{end_date}' "
      elsif start_date && !end_date
        conditions += "AND fecha_creacion_odt >= '#{start_date}' "
      elsif !start_date && end_date
        conditions += "AND fecha_creacion_odt <= '#{end_date}' "
      end
      
      # Finally!
      projects = Proyecto.find :all, :include => [:area, :opportunity], :conditions => conditions
      
      # Build the data for the first main table
      exec_buffer     = {}
      cat_buffer      = {}
      billed_odts     = []
      facturated_odts = []
      
      projects.each do |p|
        monto_soles   = p.monto_de_venta_as_soles.round
        monto_dolares = p.monto_de_venta_as_dollars.round
        
        if p.anulado?
          tipo = 'ANULADA'
        else
          tipo = TIPO_PROYECTO[p.tipo_proyecto]
        end
        
        @odt_data << [p.orden_id, p.account.name, p.opportunity.name, monto_soles, monto_dolares, p.executive.full_name, p.fecha_creacion_odt, p.fecha_de_entrega_odt, TIPO_DE_VENTA[p.tipo_de_venta], tipo]
        
        quota     = 0
        bonus     = 0
        comission = 0
        
        exec_buffer[p.executive.id] ||= {
          :sold       => 0,
          :billed     => 0,
          :facturated => 0,
          :total_odt  => 0,
          :name       => p.executive.full_name,
          :quota      => quota,
          :bonus      => bonus,
          :comission  => comission
        }
        
        exec_buffer[p.executive.id][:sold] += monto_dolares
        
        if p.account.cobranza_larga? || p.cobrado?
          exec_buffer[p.executive.id][:billed] += monto_dolares
          billed_odts << p
        end
        
        if p.has_facturas_or_boletas?
          exec_buffer[p.executive.id][:facturated] += monto_dolares
          facturated_odts << p
        end
        
        if p.tipo_proyecto == T_NUEVO_PROYECTO && !p.anulado?
          exec_buffer[p.executive.id][:total_odt] += 1
          
          cat_buffer[p.tipo_de_venta] ||= 0
          cat_buffer[p.tipo_de_venta]  += monto_dolares
          @cat_total                   += monto_dolares
        end
      end
      
      # Now, the exec table
      exec_buffer.each do |id, e|
        name       = e[:name]
        sold       = e[:sold]
        quota      = e[:quota]
        bonus      = e[:bonus]
        billed     = e[:billed]
        facturated = e[:facturated]
        comission  = e[:comission]
        total_odt  = e[:total_odt]
        
        diff        = sold - quota
        billed_diff = billed -quota
        
        if quota > 0
          productivity = ((sold * 100) / quota).round
        else
          productivity = 0
        end
        
        if total_odt > 0
          ped_prom = (sold / total_odt)
        else
          ped_prom = 0
        end
        
        # No bonus for unmet quotas, sorry. Work harder next month.
        if sold < quota
          bonus = ""
        end
        
        if billed < quota
          comission = ""
        else
          comission = (billed_diff * (comission.to_f / 100.00)).round
        end
        
        @exec_data << [name, sold, quota, diff, bonus, billed, facturated, billed_diff, comission, productivity, total_odt, ped_prom, id]
      end
      
      # Next, Categories
      TIPO_DE_VENTA.each_with_index do |c, i|
        if cat_buffer[i]
          total   = cat_buffer[i]
          if @cat_total == 0
            percent = 0
          else
            percent = ((cat_buffer[i] * 100) / @cat_total).round
          end
        else
          total   = 0.00
          percent = 0
        end
        
        @cat_data[i] = [c, total, percent]
      end
      
      # Finally, the part that everybody was waiting for: the sorts!
      @odt_data = @odt_data.sort do |a, b|
        s = params[:sort_odt].to_i
        x = a[s]
        y = b[s]
        
        # Special cases
        if [1, 2, 5, 8, 9].include? s
          # Strings, sort by lowercase
          x = x.downcase
          y = y.downcase
        end
        
        if params[:dir_odt] == "0"
          x <=> y
        else
          y <=> x
        end
      end
      
      @exec_data = @exec_data.sort do |a, b|
        s = params[:sort_exec].to_i
        x = a[s]
        y = b[s]
        
        # Special cases
        if s == 0
          # Exec name
          x = x.downcase
          y = y.downcase
        end
        
        if params[:dir_exec] == "0"
          x <=> y
        else
          y <=> x
        end
      end
      
      @cat_data = @cat_data.sort do |a, b|
        s = params[:sort_cat].to_i
        x = a[s]
        y = b[s]
        
        # Special cases
        if s == 0
          # Category name
          x = x.downcase
          y = y.downcase
        end
        
        if params[:dir_cat] == "0"
          x <=> y
        else
          y <=> x
        end
      end
    end
  end
  
  
  def executives_quotas
    # If he's not an admin, then we hardcode the user's username
    if is_supervisor?
      if params[:executive]
        executive = params[:executive]
      else
        executive = nil
      end
    else
      executive = session[:user][:id]
    end
    
    # Sort parameters default values
    params["sort_exec"] = "name" unless params["sort_exec"]
    params["dir_exec"]  = "0" unless params["dir_exec"]
    
    # Let's go with da form
    @form = Fionna.new "executives_quotas"
    
    @form.load_values params
    
    @exec_data      = []
    
    unless params[:q] # That is, no form request yet
      @form.month = Time.now.month
      @form.year  = Time.now.year
    end
    
    if @form.valid?
      date     = Time.mktime(@form.year, @form.month, 1, 0, 0, 0)
      
      # Here we go
      @exec_data = Proyecto.calculate_executives_quotas(date, @form.tisac, executive)
      
      # Are there completed comissions for this date?
      completed_comissions = ComisionesCabecera.completed_comissions_generated_on(date)
      @cc_for_user         = {}
      
      unless completed_comissions.empty?
        completed_comissions.each do |cc|
          @cc_for_user[cc.user_id] = cc.fecha_cobrada
        end
      end
      
      # Sort it!
      @exec_data = @exec_data.sort do |a, b|
        s = params[:sort_exec]
        x = a.send(s)
        y = b.send(s)
        
        # Special cases
        if s == "name"
          # Exec name
          x = x.downcase
          y = y.downcase
        end
        
        if params[:dir_exec] == "0"
          x <=> y
        else
          y <=> x
        end
      end
    end
    
    if params[:details]
      @group_a = []
      @group_b = []
      
      if params[:what] == "billed"
        @exec_data.each do |e|
          @group_a += e.billed_odts
          @group_b += e.unbilled_odts
        end
      else
        @exec_data.each do |e|
          @group_a += e.facturated_odts
          @group_b += e.unfacturated_odts
        end
      end
      
      @executive = User.find(params[:executive])
      
      render :action => "executives_quotas_details"
    end
  end
  
  
  def executives_comissions
    year  = params[:year]
    month = params[:month]
    @uid  = params[:uid]
    
    @date = Time.mktime(year, month, 1, 0, 0, 0)
    @user = User.find(@uid)
    
    # Let's get all the data!
    coms  = @user.comission_for @date
    @data = []
    
    coms.each do |c|
      b = Proyecto.calculate_executives_quotas(c.fecha_origen, "0", @uid).first
      
      @data << {
        :date      => c.fecha_origen,
        :comission => c,
        :briefings => b
      }
    end
  end
  
  
  def monthly
    @graph_accumulated = open_flash_chart_object('640', '400', url_for(:action => 'monthly_data_accumulated'), false)
    @graph_by_month = open_flash_chart_object('640', '400', url_for(:action => 'monthly_data_by_month'), false)
    @graph_by_year = open_flash_chart_object('640', '400', url_for(:action => 'monthly_data_by_year'), false)
    
    @data = Proyecto.get_ventas_by_month
    
    # What was the highest for each year?
    @highest = []
    
    @data.each do |d|
      h = 0.00
      d[1][1..-1].each do |v|
        h = v if v > h
      end
      @highest[d[0].to_i] = h
    end
  end
  
  
  def monthly_data_accumulated
    colors = REPORT_COLORS.dup
    
    data = Proyecto.get_ventas_by_month :return_cummulative
    
    g = Graph.new
    g.bg_color('#FCFAE3')
    
    data_max = 0.00
    
    data.each do |d|
      g.set_data(d[1][1..-1])
      g.line_hollow(3, 5, '0x' + colors.shift, d[0], 10);
      
      # We find out what's the max value to calculate y_max for the chart
      d[1][1..-1].each do |v|
        data_max = v if v > data_max
      end
    end
    
    y_max = 0.00
    
    while (y_max < data_max)
      y_max += 10000
    end
    
    g.set_x_labels(%w(ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SET,OCT,NOV,DIC))
    g.set_y_max(y_max)
    g.set_y_label_steps(10)
    
    render :text => g.render
  end
  
  
  def monthly_data_by_month
    colors = REPORT_COLORS.dup
    tc = params[:tc].to_f
    
    data = Proyecto.get_ventas_by_month(tc)
    
    g = Graph.new
    g.bg_color('#FCFAE3')
    
    data_max = 0.00
    
    data.each do |d|
      g.set_data(d[1][1..-1])
      g.line_hollow(3, 5, '0x' + colors.shift, d[0], 10);
      
      # We find out what's the max value to calculate y_max for the chart
      d[1][1..-1].each do |v|
        data_max = v if v > data_max
      end
    end
    
    y_max = 0.00
    
    while (y_max < data_max)
      y_max += 10000
    end
    
    g.set_x_labels(%w(ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SET,OCT,NOV,DIC))
    g.set_y_max(y_max)
    g.set_y_label_steps(10)
    
    render :text => g.render
  end
  
  
  def monthly_data_by_year
    data = Proyecto.get_ventas_by_year
    
    g = Graph.new
    g.bg_color('#FCFAE3')
    
    data_max = 0.00
    
    values = []
    labels = []
    
    2004.upto(data.keys.max) do |y|
      unless y.nil?
        values << data[y]
        labels << y
        data_max = data[y] if data[y] > data_max
      end
    end
    
    g.set_data(values)
    g.line_hollow(3, 5, '0xDF441F', 'Tendencia de Crecimiento', 10);
      
    y_max = 0.00
    
    while (y_max < data_max)
      y_max += 10000
    end
    
    g.set_x_labels(labels)
    g.set_y_max(y_max)
    g.set_y_label_steps(10)
    
    render :text => g.render
  end
  
  
  def account_movement
    @form = Fionna.new "account_movement_report"
    
    @form.load_values params
    
    # Sort criteria
    if params[:sort_column]
      @sort_column = params[:sort_column].to_i
    else
      @sort_column = 0
    end
    
    if params[:sort_direction] && (['0', '1'].include? params[:sort_direction])
      @sort_direction = params[:sort_direction]
    else
      @sort_direction = "0"
    end
    
    unless params[:q]
      @form.report_monthly_client_year = (Time.now.year - 1).to_s
    end
    
    if @form.valid?
      year = @form.report_monthly_client_year
      
      if is_supervisor?
        exec = @form.executive
      else
        exec = session[:user][:id]
      end
      
      tipo = @form.tipo_de_venta
      
      @data = Proyecto.get_account_movement_data(year, exec, tipo, @sort_column, @sort_direction)
    end
  end
  
  
  def commercial_briefing
    @form = Fionna.new "commercial_briefing_report"
    
    # Sort criteria
    if params[:sort1]
      @sort1 = params[:sort1].to_i
    else
      @sort1 = 0
    end
    
    if params[:dir1] && (['0', '1'].include? params[:dir1])
      @dir1 = params[:dir1]
    else
      @dir1 = "0"
    end
    
    if params[:sort2]
      @sort2 = params[:sort2].to_i
    else
      @sort2 = 0
    end
    
    if params[:dir2] && (['0', '1'].include? params[:dir2])
      @dir2 = params[:dir2]
    else
      @dir2 = "0"
    end
    
    if params[:sort3]
      @sort3 = params[:sort3].to_i
    else
      @sort3 = 0
    end
    
    if params[:dir3] && (['0', '1'].include? params[:dir3])
      @dir3 = params[:dir3]
    else
      @dir3 = "0"
    end
    
    if params[:q]
      @form.load_values params
    else
      @form.start_month = Time.now.month.to_s
      @form.start_year  = Time.now.year.to_s
      @form.end_month   = Time.now.month.to_s
      @form.end_year    = Time.now.year.to_s
    end
    
    if @form.valid?
      @data_groups = Proyecto.get_commercial_briefing_data(:groups, @form.start_month, @form.start_year, @form.end_month, @form.end_year, @sort1, @dir1)
      
      @data_execs  = Proyecto.get_commercial_briefing_data(:execs, @form.start_month, @form.start_year, @form.end_month, @form.end_year, @sort2, @dir2)
      
      @data_ratios = Proyecto.get_commercial_briefing_data_ratios(@form.start_month, @form.start_year, @form.end_month, @form.end_year,@sort3, @dir3)
    end
  end
  
  
  def design
    # He must be an Admin or an Executive to see this report
    redirect_to(:controller => "dashboard", :action => "index") unless is_supervisor?
    
    conditions = "con_orden_de_trabajo='0' AND NOT #{SQL_VERA_DELETED} "
    
    # Sort parameters default values
    params["sort"]  = "0" unless params["sort"]
    params["dir"]   = "0" unless params["dir"]

    # Let's go with da form
    @form = Fionna.new "design_report"
    
    @odt_data  = []
    @exec_data = []
    @cat_data  = []
    @cat_total = 0
    
    if params[:q]
      @form.load_values params
    else
      @form.fdesign_start_month = Time.now.month.to_s
      @form.fdesign_start_year  = Time.now.year.to_s
      @form.fdesign_end_month   = Time.now.month.to_s
      @form.fdesign_end_year    = Time.now.year.to_s
      
      @form.estado_diseno       = E_DISENO_EN_PROCESO.to_s
    end
    
    if @form.valid?
      conditions += "AND opportunities.assigned_user_id='#{@form.executive}' " unless @form.executive == "-1"
      
      conditions += "AND proyectos.account_id='#{@form.client}' " unless @form.client == "-1"
      
      conditions += "AND proyecto_areas.encargado_diseno='#{@form.designer}' " unless @form.designer == "-1"
      
      conditions += "AND proyecto_areas.estado_diseno='#{@form.estado_diseno}' " unless @form.estado_diseno == "-1"
      
      conditions += "AND opportunities.sales_stage='#{@form.estado}' " unless @form.estado == "-1"
      
      conditions += build_condition_for_date_range("opportunities.date_entered", @form.fcreate_start_day, @form.fcreate_start_month, @form.fcreate_start_year, @form.fcreate_end_day, @form.fcreate_end_month, @form.fcreate_end_year)
      
      conditions += build_condition_for_date_range("opportunities.date_closed", @form.fclose_start_day, @form.fclose_start_month, @form.fclose_start_year, @form.fclose_end_day, @form.fclose_end_month, @form.fclose_end_year)
      
      conditions += build_condition_for_date_range("proyectos.fecha_entrega_diseno", @form.fdesign_start_day, @form.fdesign_start_month, @form.fdesign_start_year, @form.fdesign_end_day, @form.fdesign_end_month, @form.fdesign_end_year)
      
      # Finally!
      projects = Proyecto.find :all, :include => [:area, :opportunity], :conditions => conditions
      
      # Build the data for the first main table
      exec_buffer = {}
      cat_buffer  = {}
      
      projects.each do |p|
#        monto_soles   = p.monto_de_venta_as_soles.round
        monto_dolares = p.monto_de_oportunidad_as_dollars.round
        if p.area.encargado_diseno == ""
          designer = ""
        else
          designer = User.find(p.area.encargado_diseno).full_name
        end
        
        @odt_data << [p.id, p.account.name, p.opportunity.name, p.opportunity.description, p.opportunity.date_entered, p.opportunity.date_closed, p.fecha_entrega_diseno, monto_dolares, p.executive.full_name, designer, p.opportunity.probability, p.opportunity.sales_stage, p.opportunity.next_step, p.area.estado_diseno]
      end
      
      # Finally, the part that everybody was waiting for: the sorts!
      @odt_data = @odt_data.sort do |a, b|
        s = params[:sort].to_i
        x = a[s]
        y = b[s]
        
        # Special cases
        if [1, 2, 3, 8, 9, 11, 12].include? s
          # Strings, sort by lowercase
          x = x.downcase
          y = y.downcase
        end
        
        if params[:dir] == "0"
          x <=> y
        else
          y <=> x
        end
      end
    end
    
    @projects = []
  end
  
  
  def build_condition_for_date_range(sql_field, start_day, start_month, start_year, end_day, end_month, end_year)
    # Start Date
    if (start_day == "-1" && start_month == "-1" && start_year != "-1")
      # He chose only year and no month nor day, this means to consider
      # the start of the whole year
      start_date = Time.mktime(start_year, 1, 1)
    elsif (start_day == "-1" && start_month != "-1" && start_year != "-1")
      # He chose year and month
      start_date = Time.mktime(start_year, start_month, 1)
    elsif (start_day != "-1" && start_month != "-1" && start_year != "-1")
      # He chose all three
      start_date = Time.mktime(start_year, start_month, start_day)
    else
      # He chose some other thing which I can't think of
      start_date = false
    end
    
    # Now the End Date -- similar to Start Date, so read the comments above
    if (start_day == "-1" && end_month == "-1" && end_year != "-1")
      end_date = Time.mktime(end_year, 12, 31, 23, 59, 59)
    elsif (start_day == "-1" && end_month != "-1" && end_year != "-1")
      # He chose year and month
      # The Date.civil thing is to find out the last day of the month.
      # Not so clever, and I don't like it that much, but works.
      end_date = Time.mktime(end_year, end_month, Date.civil(end_year.to_i, end_month.to_i, -1).day, 23, 59, 59)
    elsif (end_day != "-1" && end_month != "-1" && end_year != "-1")
      end_date = Time.mktime(end_year, end_month, end_day, 23, 59, 59)
    else
      end_date = false
    end
    
    start_date = start_date.strftime("%Y-%m-%d %H:%M:%S") if start_date
    end_date   = end_date.strftime("%Y-%m-%d %H:%M:%S") if end_date
    
    if start_date && end_date
      return "AND #{sql_field} BETWEEN '#{start_date}' AND '#{end_date}' "
    elsif start_date && !end_date
      return "AND #{sql_field} >= '#{start_date}' "
    elsif !start_date && end_date
      return "AND #{sql_field} <= '#{end_date}' "
    end
    
    return ""
  end
  
  
  def facturation_flow
    conditions = ""
    @form      = Fionna.new "facturation_flow_report"
    set_companies_for @form
    
    @form.load_values params
    
    if @form.valid? && params[:q]
      unless @form.client == "-1"
        conditions += "AND proyectos.account_id='#{@form.client}'"
      end
      
      if @form.empresa_vendedora == "-1"
        conditions += "AND proyectos.empresa_vendedora IN #{companies_sql_list}"
      else
        conditions += "AND proyectos.empresa_vendedora='#{@form.empresa_vendedora}'"
      end
    end
    
    facturas = Factura.find_by_sql "
      SELECT DISTINCT facturas.*
        FROM facturas,
             ordenes_facturas,
             proyectos
       WHERE ordenes_facturas.factura_id=facturas.id
         AND ordenes_facturas.proyecto_id=proyectos.id
         AND cargo_cobranza='1'
         AND cobrada='0'
         AND fecha_probable IS NOT NULL
         AND fecha_probable <> ''
         AND anulada='0'
         AND completa='1'
         AND en_blanco='0'
         " + conditions + "
         ORDER BY fecha_emision"
    
    if facturas.empty?
      @list = {}
    else
      facturas = facturas.sort_by { |f| f.fecha_probable }
      
      # Sum
      @list   = {}
      @totals = []
      @gtotal = 0.00
      
      EMPRESA_VENDEDORA.size.times do
        @totals << 0.00
      end
      
      facturas.each do |f|
        date        = f.fecha_probable.strftime("%Y%m%d")
        
        unless @list[date]
          @list[date] = {
            :soles    => 0.00,
            :dollars  => 0.00,
            :facturas => []
          }
        end
        
        @list[date][:soles]    += f.monto_activo_as_soles
        @list[date][:dollars]  += f.monto_activo_as_dollars
        @list[date][:facturas] << f
        @totals[f.empresa]     += f.monto_activo_as_dollars
        @gtotal                += f.monto_activo_as_dollars
      end
      
      @start_date = facturas.first.fecha_probable
      @end_date   = facturas.last.fecha_probable
    end
  end
  
  
  def facturation_flow_details
    @client            = params[:client]
    @empresa_vendedora = params[:empresa]
    @date              = params[:date]
    conditions        = ""
    
    # Convert date
    @date = Time.at @date.to_i
    
    if @client == "-1"
      @client_name = "(Todos)"
    else
      conditions  += "AND proyectos.account_id='#{@client}'"
      @client_name = Account.find(@client).name
    end
    
    if @empresa_vendedora == "-1"
      @empresa_name = "(Todas)"
    else
      conditions += "AND proyectos.empresa_vendedora='#{@empresa_vendedora}'"
      @empresa_name = EMPRESA_VENDEDORA[@empresa_vendedora.to_i]
    end
    
    conditions += get_condition_for_form_date_range(@date.month, @date.year, @date.month, @date.year, "facturas.fecha_probable")
    
    @list = Proyecto.find_by_sql "
      SELECT DISTINCT proyectos.*
        FROM facturas,
             ordenes_facturas,
             proyectos
       WHERE ordenes_facturas.factura_id=facturas.id
         AND ordenes_facturas.proyecto_id=proyectos.id
         AND cargo_cobranza='1'
         AND cobrada='0'
         AND fecha_probable IS NOT NULL
         AND anulada='0'
         AND completa='1'
         AND en_blanco='0'
         " + conditions + "
         ORDER BY fecha_de_entrega_odt"
  end
  
  
  def notifications
    @form      = Fionna.new "notifications_report"
    conditions = "1=1"
    
    if params[:q]
      @form.load_values params
      
      if @form.valid?
        unless @form.tipo == "-1"
          conditions += " AND tipo='#{@form.tipo}'"
        end
        
        conditions += get_condition_for_form_date_range(@form.start_month, @form.start_year, @form.end_month, @form.end_year, "created_on")
      end
    end
    
    notifications = Notificacion.find_by_sql "SELECT * FROM notificaciones WHERE " + conditions + " ORDER BY created_on DESC LIMIT 50"
    
    @notifications = notifications.select do |n|
      n unless n.proyecto.nil?
    end
  end
  
  
  def odt_guias
    odts = Proyecto.find_by_sql "SELECT * FROM proyectos WHERE con_orden_de_trabajo='1' AND facturado='1' AND anulado='0'"
    
    @odts = odts.select do |o|
      has_guias    = o.active_guias.size > 1
      has_facturas = o.of.size > 1
      
      if has_guias && has_facturas
        ok = false
        o.active_guias.each do |g|
          ok = true if !g.facturada?
        end
      else
        ok = false
      end
      
      ok
    end
    
    @odts.sort_by { |o| o.orden_id }
  end
  
  
  def billing_weekly_flow
    date = Time.now
    
    # Ok, let's get the start and end dates of the week
    dstart = (date - (date.strftime("%w").to_i - 1).days) # Monday
    dend   = (dstart + 5.days)                            # Saturday
    
    @flow = Factura.get_flow_for_week(dstart, dend)
  end
  
  
  def truput_estimado_mes
    @form = Fionna.new "truput_estimado_mes"
    @data = []
    
    @form.load_values params
    
    unless params[:q]
      end_date = Time.now + 5.months
      
      @form.start_month = Time.now.month.to_s
      @form.start_year  = Time.now.year.to_s
      @form.end_month   = end_date.month.to_s
      @form.end_year    = end_date.year.to_s
    end
    
    if @form.valid?
      conditions = get_condition_for_form_date_range(@form.start_month, @form.start_year, @form.end_month, @form.end_year, "opportunities.date_closed")
      
      # If you modify this query, be sure to update the query on
      # the detail below too
      proyectos = Proyecto.find_by_sql "
        SELECT proyectos.*
          FROM proyectos,
               opportunities
         WHERE opportunities.id=proyectos.opportunity_id
           AND NOT #{SQL_VERA_DELETED}
           AND opportunities.sales_stage<>'Closed Lost'
           AND tipo_proyecto='#{T_NUEVO_PROYECTO}'
           AND empresa_vendedora <> #{TISAC}
           AND proyectos.anulado='0'
           #{conditions}
      "
      
      truput_percentage = @form.truput.to_i / 100.0
      
      predata = {}
      @totals = {}
      
      proyectos.each do |p|
        # The index is the month
        f     = p.opportunity.date_closed
        index = Time.mktime(f.year, f.month, 1, 0, 0, 0)
        
        # Starting values
        predata[index] ||= OpenStruct.new({
          :date   => index,
          :truput => 0.00,
          :tipos  => TIPO_DE_VENTA.collect { [0.00, 0.00] }
        })
        
        @totals[index] ||= OpenStruct.new({
          :t => 0.00,
          :a => 0.00,
          :b => 0.00
        })
        
        monto = 0.00
        
        if p.con_orden_de_trabajo?
          if p.opportunity.sales_stage == 'Closed Won'
            monto                  = (p.monto_de_venta_as_dollars * truput_percentage).round
            predata[index].truput += monto
          end
        else
          unless p.opportunity.probability.nil?
            m = (p.opportunity.amount_as_dollars * truput_percentage).round
            
            if p.opportunity.probability >= @form.probabilidad.to_i
              predata[index].tipos[p.tipo_de_venta][0] += m
              @totals[index].a                         += m
              monto                                     = m
            else
              predata[index].tipos[p.tipo_de_venta][1] += m
              @totals[index].b                         += m
            end
          end
        end
        
        @totals[index].t += monto
      end
      
      @data = predata.collect { |k, v| v }
      @data = @data.sort_by { |d| d.date }
    end
  end
  
  
  def truput_estimado_mes_detalle
    @month       = params[:month].to_i
    @year        = params[:year].to_i
    @truput      = params[:truput].to_i
    @what        = params[:what]
    conditions   = ""
    
    if @what == "odt"
      conditions = "AND con_orden_de_trabajo='1' AND opportunities.sales_stage='Closed Won'"
    else
      @type         = params[:type].to_i
      @probability  = params[:probability]
      @direction    = params[:direction].to_i
      
      conditions   += " AND con_orden_de_trabajo='0' AND tipo_de_venta='#{@type}' AND opportunities.probability IS NOT NULL AND opportunities.sales_stage<>'Closed Lost'"
      
      if @direction == 0
        conditions += " AND opportunities.probability >= '#{@probability}'"
      else
        conditions += " AND opportunities.probability < '#{@probability}'"
      end
    end
    
    conditions += get_condition_for_form_date_range(@month, @year, @month, @year, "opportunities.date_closed")
    
    proyectos = Proyecto.find_by_sql "
      SELECT proyectos.*
        FROM proyectos,
             opportunities
       WHERE proyectos.opportunity_id=opportunities.id
         AND NOT #{SQL_VERA_DELETED}
         AND tipo_proyecto='#{T_NUEVO_PROYECTO}'
         AND empresa_vendedora <> #{TISAC}
         AND proyectos.anulado='0'
         #{conditions}
    ORDER BY id
    "
    
    @data = {}
    
    proyectos.each do |p|
      if @what == "odt"
        monto = p.monto_de_venta_as_dollars
      else
        monto = p.opportunity.amount_as_dollars
      end
      
      @data[p.executive.full_name] ||= []
      @data[p.executive.full_name] << OpenStruct.new({
        :project      => p,
        :probabilidad => p.opportunity.probability,
        :truput       => (monto * (@truput / 100.0)).round,
        :monto        => monto
      })
    end
    
    @executives = @data.keys.sort
  end
  
  
  def estimado_cierre_de_venta
    @form = Fionna.new "estimado_cierre_de_venta"
    @data = []
    
    @form.load_values params
    
    unless params[:q]
      end_date = Time.now + 5.months
      
      @form.start_month = Time.now.month.to_s
      @form.start_year  = Time.now.year.to_s
      @form.end_month   = end_date.month.to_s
      @form.end_year    = end_date.year.to_s
    end
    
    if @form.valid?
      conditions  = get_condition_for_form_date_range(@form.start_month, @form.start_year, @form.end_month, @form.end_year, "date_closed")
      
      unless @form.executive == "-1"
        conditions += " AND opportunities.assigned_user_id='#{@form.executive}'"
      end
      
      # Estimates calculation go go go
      proyectos = Proyecto.find_by_sql "
        SELECT proyectos.*
          FROM proyectos,
               opportunities
         WHERE opportunities.id=proyectos.opportunity_id
           AND NOT #{SQL_VERA_DELETED}
           AND opportunities.sales_stage<>'Closed Lost'
           AND tipo_proyecto='#{T_NUEVO_PROYECTO}'
           AND empresa_vendedora <> #{TISAC}
           AND proyectos.anulado='0'
           AND proyectos.con_orden_de_trabajo='0'
           #{conditions}"
      
      predata = {}
      @totals = {}
      
      proyectos.each do |p|
        # The index is the month
        f     = p.opportunity.date_closed
        index = Time.mktime(f.year, f.month, 1, 0, 0, 0)
        
        # Starting values
        predata[index] ||= OpenStruct.new({
          :date   => index,
          :truput => 0.00,
          :tipos  => TIPO_DE_VENTA.collect { [0.00, 0.00] }
        })
        
        @totals[index] ||= OpenStruct.new({
          :t => 0.00,
          :a => 0.00,
          :b => 0.00
        })
        
        monto = 0.00
        
        unless p.opportunity.probability.nil?
          m = p.opportunity.amount_as_dollars.round
          
          if p.opportunity.probability >= @form.probabilidad.to_i
            predata[index].tipos[p.tipo_de_venta][0] += m
            @totals[index].a                         += m
            monto                                    += m
          else
            predata[index].tipos[p.tipo_de_venta][1] += m
            @totals[index].b                         += m
          end
        end
        
        @totals[index].t += monto
      end
      
      # Now, the ventas in the same period
      conditions  = get_condition_for_form_date_range(@form.start_month, @form.start_year, @form.end_month, @form.end_year, "fecha_creacion_odt")
      
      unless @form.executive == "-1"
        conditions += " AND opportunities.assigned_user_id='#{@form.executive}'"
      end
      
      # This is the same query of the detail -- if you modify this query
      # be sure to update the one below
      # BTW, this is to calculate the "Ventas Cerradas" column
      proyectos = Proyecto.find_by_sql "
        SELECT proyectos.*
          FROM proyectos,
               opportunities
         WHERE opportunities.id=proyectos.opportunity_id
           AND NOT #{SQL_VERA_DELETED}
           AND opportunities.sales_stage='Closed Won'
           AND tipo_proyecto='#{T_NUEVO_PROYECTO}'
           AND empresa_vendedora <> #{TISAC}
           AND proyectos.anulado='0'
           AND proyectos.con_orden_de_trabajo='1'
           #{conditions}"
      
      # FIXME this code is duplicated from above due to lack of time
      proyectos.each do |p|
        # The index is the month
        f     = p.fecha_creacion_odt
        index = Time.mktime(f.year, f.month, 1, 0, 0, 0)
        
        # Starting values
        predata[index] ||= OpenStruct.new({
          :date   => index,
          :truput => 0.00,
          :tipos  => TIPO_DE_VENTA.collect { [0.00, 0.00] }
        })
        
        @totals[index] ||= OpenStruct.new({
          :t => 0.00,
          :a => 0.00,
          :b => 0.00
        })
        
        monto                  = p.monto_de_venta_as_dollars.round
        predata[index].truput += monto
        
        @totals[index].t += monto
      end
      
      @data = predata.collect { |k, v| v }
      @data = @data.sort_by { |d| d.date }
    end
  end
  
  
  def estimado_cierre_de_venta_detalle
    @month       = params[:month].to_i
    @year        = params[:year].to_i
    @what        = params[:what]
    conditions   = ""
    
    if @what == "odt"
      conditions += " AND con_orden_de_trabajo='1' AND opportunities.sales_stage='Closed Won'"
      date_field    = "fecha_creacion_odt"
    else
      @type         = params[:type].to_i
      @probability  = params[:probability]
      @direction    = params[:direction].to_i
      date_field    = "date_closed"
      
      conditions   += " AND con_orden_de_trabajo='0' AND tipo_de_venta='#{@type}' AND opportunities.probability IS NOT NULL AND opportunities.sales_stage<>'Closed Lost'"
      
      if @direction == 0
        conditions += " AND opportunities.probability >= '#{@probability}'"
      else
        conditions += " AND opportunities.probability < '#{@probability}'"
      end
    end
    
    unless params[:executive] == "-1"
      conditions += " AND opportunities.assigned_user_id='#{params[:executive]}'"
    end
    
    conditions += get_condition_for_form_date_range(@month, @year, @month, @year, date_field)
    
    proyectos = Proyecto.find_by_sql "
      SELECT proyectos.*
        FROM proyectos,
             opportunities
       WHERE proyectos.opportunity_id=opportunities.id
         AND NOT #{SQL_VERA_DELETED}
         AND tipo_proyecto='#{T_NUEVO_PROYECTO}'
         AND empresa_vendedora<>'#{TISAC}'
         AND anulado='0'
         #{conditions}
    ORDER BY id"
    
    @data = {}
    
    proyectos.each do |p|
      if @what == "odt"
        monto = p.monto_de_venta_as_dollars.round
      else
        monto = p.opportunity.amount_as_dollars.round
      end
      
      @data[p.executive.full_name] ||= []
      @data[p.executive.full_name] << OpenStruct.new({
        :project      => p,
        :monto        => monto,
        :probabilidad => p.opportunity.probability,
        :date_closed  => p.opportunity.date_closed,
        :closed       => p.con_orden_de_trabajo?
      })
    end
    
    @executives = @data.keys.sort
  end
  
  
  def odt_consumption
    @form = Fionna.new "odt_consumption"
    
    if params[:q]
      @form.load_values params
    else
      @form.start_creation_month = Time.now.month.to_s
      @form.start_creation_year  = Time.now.year.to_s
      @form.end_creation_month   = Time.now.month.to_s
      @form.end_creation_year    = Time.now.year.to_s
      @form.estado_facturacion   = [F_POR_FACTURAR, F_FACTURA_PARCIAL, F_FACTURA_TOTAL]
      @form.estado_cobranza      = [C_POR_COBRAR, C_COBRADO]
      @form.tipo_proyecto        = [T_NUEVO_PROYECTO.to_s]
      @form.con_guia             = "1"
      @form.sin_guia             = "1"
    end
    
    if @form.valid?
      conditions  = ""
      
      conditions += get_condition_for_form_date_range(@form.start_creation_month, @form.start_creation_year, @form.end_creation_month, @form.end_creation_year, "proyectos.fecha_creacion_odt")
      
      conditions += get_condition_for_form_date_range(@form.start_client_month, @form.start_client_year, @form.end_client_month, @form.end_client_year, "proyectos.fecha_de_recepcion_del_cliente")
      
      conditions += "AND status_cobranza IN (" + @form.estado_cobranza.join(',') + ")"
      
      conditions += "AND status_facturacion IN (" + @form.estado_facturacion.join(',') + ")"
      
      conditions += "AND tipo_proyecto IN (" + @form.tipo_proyecto.join(',') + ")"
      
      unless @form.empresa_vendedora == "-1"
        conditions += " AND empresa_vendedora='#{@form.empresa_vendedora}'"
      end
      
      unless @form.client == "-1"
        conditions += " AND account_id='#{@form.client}'"
      end
    end
    
    odts = Proyecto.find_by_sql "
      SELECT *
        FROM proyectos
       WHERE con_orden_de_trabajo='1'
         AND anulado='0'
         #{conditions}
    ORDER BY orden_id DESC
         "
    
    @data = []
    odts.each do |o|
      add_it = false
      
      if @form.con_guia == "1" && @form.sin_guia == "1"
        add_it = true
      else
        if @form.con_guia == "1" && !o.guias.empty?
          add_it = true
        end
        
        if @form.sin_guia == "1" && o.guias.empty?
          add_it = true
        end
      end
      
      # OK
      if add_it
        monto_odt = o.monto_de_venta_as_dollars
        
        if monto_odt == 0.00
          insumos = pinsumos = servicios = pservicios = compras = pcompras = 0
        else
          insumos   = o.total_sispre_insumos
          pinsumos  = ((insumos * 100) / monto_odt).round
          
          servicios  = o.total_sispre_servicios
          pservicios = ((servicios * 100) / monto_odt).round
          
          compras  = o.total_sispre_compras_libres
          pcompras = ((compras * 100) / monto_odt).round
        end
        
        i = OpenStruct.new({
          :orden_id   => o.orden_id,
          :client     => o.account.name,
          :monto_odt  => monto_odt,
          :insumos    => insumos,
          :pinsumos   => pinsumos,
          :servicios  => servicios,
          :pservicios => pservicios,
          :compras    => compras,
          :pcompras   => pcompras
        })
        
        @data << i
      end
    end
  end
  
  
  def facturation_pending
    @form = Fionna.new "facturation_pending" 
    
    conditions = "
          proyectos.opportunity_id=opportunities.id
      AND opportunities.assigned_user_id=users.id
      AND opportunities.sales_stage IN ('Closed Won', 'Closed Lost')
      AND proyectos.con_orden_de_trabajo='1'
      AND NOT #{SQL_VERA_DELETED}
      AND proyectos.anulado='0'
      AND proyectos.tipo_proyecto='#{T_NUEVO_PROYECTO}'
      AND status_facturacion IN (#{F_POR_FACTURAR}, #{F_FACTURA_PARCIAL})
    "
    
    if is_supervisor?
      if params[:uid]
        conditions += " AND opportunities.assigned_user_id='" + params[:uid] + "'"
      end
    else
      conditions += " AND opportunities.assigned_user_id='" + session[:user][:id] + "'"
    end
    
    if params[:q]
      @form.load_values params
    else
      unless params[:year] == "-1"
        conditions += " AND YEAR(proyectos.fecha_creacion_odt) = '#{params[:year]}'"
      end
    end
    
    if @form.valid?
      unless @form.year == "-1"
        conditions += " AND YEAR(proyectos.fecha_creacion_odt) = '#{@form.year}'"
      end
    end
    
    data = Proyecto.find_by_sql "
      SELECT proyectos.*
        FROM proyectos,
             opportunities,
             users
       WHERE #{conditions}
    ORDER BY users.first_name,
             users.last_name,
             proyectos.orden_id"
    
    if params[:uid]
      @data = data
      
      render :action => "facturation_pending_details"
    else
      # Consolidate everything by Executive
      execs = {}
      
      data.each do |d|
        execs[d.executive]    ||= [0, 0.00]
        execs[d.executive][0]  += 1
        execs[d.executive][1]  += d.monto_de_venta_as_dollars
      end
      
      @data = []
      execs.each do |k, v|
        @data << {
          :uid    => k.id,
          :user   => k.full_name,
          :count  => v[0],
          :amount => v[1]
        }
      end
      
      @data = @data.sort_by { |d| d[:user] }
    end
  end
  
  
  def costos_por_odt
    @data = Proyecto.find_by_sql "
      SELECT proyectos.*
        FROM guias_de_remisiones,
             proyectos
       WHERE guias_de_remisiones.proyecto_id=proyectos.id
         AND ultima_guia='1'
    ORDER BY proyectos.orden_id
    "
  end
  
  
  def odts_sin_fecha_cierre
    @form = Fionna.new "resumen_truput_mensual"
    @data = []
    
    # Sort parameters default values
    params["sort"] = "odt" unless params["sort"]
    params["dir"]  = "1" unless params["dir"]
    
    @form.load_values params
    
    unless params[:q]
      end_date = Time.now - 1.month
      
      @form.start_month = "1"
      @form.start_year  = end_date.year.to_s
      @form.end_month   = end_date.month.to_s
      @form.end_year    = end_date.year.to_s
      
      @form.empresa     = ["0", "1", "2", "3"]
    end
    
    if @form.valid?
      conditions = get_condition_for_form_date_range(@form.start_month, @form.start_year, @form.end_month, @form.end_year, "fecha_creacion_odt")
      
      conditions += "AND empresa_vendedora IN (" + @form.empresa.join(',') + ")"
      
      # Ok guys, here we go!
      @data = Proyecto.find_by_sql "
        SELECT *
          FROM proyectos
         WHERE con_orden_de_trabajo='1'
           AND odt_cerrada='0'
           AND anulado='0'
           AND tipo_proyecto='#{T_NUEVO_PROYECTO}'
               #{conditions}
      ORDER BY orden_id
      "
      
      # Sortie, sortie
      sort = params["sort"]
      dir  = params["dir"]
      
      @data = @data.sort do |a, b|
        if sort == "odt"
          x = a.orden_id
          y = b.orden_id
        elsif sort == "cliente"
          x = a.account.name.strip.downcase
          y = b.account.name.strip.downcase
        elsif sort == "descripcion"
          x = a.nombre_proyecto.strip.downcase
          y = b.nombre_proyecto.strip.downcase
        elsif sort == "monto"
          x = a.monto_de_venta_as_dollars
          y = b.monto_de_venta_as_dollars
        elsif sort == "fecha_entrega"
          x = a.fecha_de_entrega_odt 
          y = b.fecha_de_entrega_odt
        else
          ""
        end
        
        if dir == "0"
          x <=> y
        else
          y <=> x
        end
      end
    end
  end
  
  
  def resumen_truput_mensual
    @form = Fionna.new "resumen_truput_mensual"
    @data = []
    
    @form.load_values params
    
    unless params[:q]
      end_date = Time.now - 1.month
      
      @form.start_month = "1"
      @form.start_year  = end_date.year.to_s
      @form.end_month   = end_date.month.to_s
      @form.end_year    = end_date.year.to_s
      
      @form.empresa     = ["0", "1", "2", "3"]
    end
    
    if @form.valid?
      conditions = get_condition_for_form_date_range(@form.start_month, @form.start_year, @form.end_month, @form.end_year, "fecha_cierre_odt")
      
      conditions += "AND empresa_vendedora IN (" + @form.empresa.join(',') + ")"
      
      ps = Proyecto.find_by_sql "
        SELECT *
          FROM proyectos
         WHERE odt_cerrada='1'
           AND con_orden_de_trabajo='1'
               #{conditions}
      ORDER BY orden_id
      "
      
      if params[:detailed]
        @data     = ps
        @date     = Date.civil(@form.start_year.to_i, @form.start_month.to_i, 1)
        
        render :action => "resumen_truput_mensual_detail.rhtml"
      else
        data = {}
        
        ps.each do |p|
          d    = p.fecha_cierre_odt
          date = Date::civil(d.year, d.month, 1) # We only deal with months
          
          data[date] ||= OpenStruct.new({
            :date            => date,
            :amount          => 0.00,
            :variable_cost   => 0.00,
            :truput          => 0.00,
            :monthly_truput  => 0.00,
            :facturated      => 0.00,
            :difference      => 0.00,
          })
          
          data[date].amount         += p.monto_de_venta_as_dollars
          data[date].variable_cost  += p.costo_variable
          data[date].truput         += p.truput
          data[date].facturated     += p.monto_facturado_as_dollars
          data[date].difference     += p.monto_de_venta_as_dollars - p.monto_facturado_as_dollars
        end
        
        data.each do |k, v|
          unless data[k].amount == 0.00
            data[k].monthly_truput = ((data[k].truput / data[k].amount) * 100).round
            puts k
            puts data[k].amount.to_s + " - " + data[k].truput.to_s
          end
        end
        
        @data = data.values.sort_by { |d| d.date  }
      end
    end
  end
  
  
  def otras_variables
    @form = Fionna.new "otras_variables"
    @data = []
    
    details = params[:details]
    
    @form.load_values params
    
    unless params[:q]
      end_date = Time.now - 1.month
      
      @form.start_month = "1"
      @form.start_year  = end_date.year.to_s
      @form.end_month   = end_date.month.to_s
      @form.end_year    = end_date.year.to_s
      
      @form.empresa     = ["0", "1", "2", "3"]
    end
    
    if @form.valid?
      conditions = get_condition_for_form_date_range(@form.start_month, @form.start_year, @form.end_month, @form.end_year, "fecha_creacion_odt")
      
      conditions += "AND empresa_vendedora IN (" + @form.empresa.join(',') + ")"
      
      ps = Proyecto.find_by_sql "
        SELECT *
          FROM proyectos
         WHERE 1=1
               #{conditions}
      ORDER BY orden_id
      "
      
      data = {}
      odts = []
      
      ps.each do |p|
        d    = p.fecha_creacion_odt
        date = Date::civil(d.year, d.month, 1) # We only deal with months
        
        data[date] ||= OpenStruct.new({
          :date              => date,
          :count             => 0,
          :new_count         => 0,
          :new_amount        => 0.00,
          :new_vc            => 0.00,
          :garantias_count   => 0,
          :garantias_amount  => 0.00,
          :reclamos_count    => 0,
          :reclamos_amount   => 0.00,
          :internas_count    => 0,
          :internas_amount   => 0.00,
          :otros_count       => 0,
          :otros_amount      => 0.00,
          :anuladas_count    => 0,
          :anuladas_amount   => 0.00,
          
          :percent           => 0,
          :new_percent       => 0,
          :garantias_percent => 0,
          :reclamos_percent  => 0,
          :internas_percent  => 0,
          :otros_percent     => 0,
          :anuladas_percent  => 0,
        })
        
        data[date].count += 1
        odts << p if details == "count"
        
        if p.anulado?
          data[date].anuladas_count  += 1
          data[date].anuladas_amount += p.costo_variable
          odts << p if details == "anuladas"
          
        elsif p.tipo_proyecto == T_NUEVO_PROYECTO
          data[date].new_count  += 1
          data[date].new_amount += p.monto_de_venta_as_dollars
          data[date].new_vc     += p.costo_variable
          odts << p if details == "new"
          
        elsif p.tipo_proyecto == T_GARANTIA
          data[date].garantias_count  += 1
          data[date].garantias_amount += p.costo_variable
          odts << p if details == "garantias"
          
        elsif p.tipo_proyecto == T_RECLAMO
          data[date].reclamos_count  += 1
          data[date].reclamos_amount += p.costo_variable
          odts << p if details == "reclamos"
          
        elsif p.tipo_proyecto == T_ORDEN_INTERNA
          data[date].internas_count  += 1
          data[date].internas_amount += p.costo_variable
          odts << p if details == "internas"
          
        elsif p.tipo_proyecto == T_OTRO
          data[date].otros_count  += 1
          data[date].otros_amount += p.costo_variable
          odts << p if details == "otros"
        end
        
      end
      
      if details.nil?
        @data = data.values.sort_by { |d| d.date  }
        
        # Calculate percentages
        @data.map do |d|
          d.new_percent       = (d.new_count * 100) / d.count
          d.garantias_percent = (d.garantias_count * 100) / d.count
          d.reclamos_percent  = (d.reclamos_count * 100) / d.count
          d.internas_percent  = (d.internas_count * 100) / d.count
          d.otros_percent     = (d.otros_count * 100) / d.count
          d.anuladas_percent  = (d.anuladas_count * 100) / d.count
          
          d
        end
      else
        @data = odts
        @date = Date.civil(@form.start_year.to_i, @form.start_month.to_i, 1)
        
        if details == "new"
          @what = "Cant. ODTs Vendidas"
        elsif details == "count"
          @what = "ODTs generadas"
        elsif details == "garantias"
          @what = "Garant&iacute;as"
        elsif details == "reclamos"
          @what = "Reclamos"
        elsif details == "internas"
          @what = "Internas"
        elsif details == "otros"
          @what = "Otros"
        elsif details == "anuladas"
          @what = "Anuladas"
        end
        
        render :action => "otras_variables_detail"
      end
      
    else
      @data = []
    end
    
  end
  
  
  def t
    rucs = Account.find_by_sql "SELECT sic_code, COUNT(*) AS t FROM accounts where deleted='0' GROUP BY sic_code ORDER BY sic_code"
    
    accounts = []
    
    rucs.each do |r|
      if r.t.to_i > 1
        as = Account.find_all_by_sic_code r.sic_code
        
        as.each do |a|
          accounts << a
        end
      end
    end
    
    accounts = accounts.sort_by { |a| (a.ruc.nil? ? '' : a.ruc) }
    @data    = accounts
    
    render :layout => false
  end
  
  
  def t2
    @projects = Proyecto.find_by_sql "
      SELECT proyectos.*
        FROM proyectos,
             pt_OT_Cabecera
       WHERE pt_OT_Cabecera.cod_ot=proyectos.orden_id
         AND fecha_final BETWEEN '2009-01-01 00:00:00' AND '2009-01-10 23:59:59'
         AND fecha_final IS NOT NULL
         AND cerrar_ot_inicial='S'
    ORDER BY proyectos.orden_id"
  end
end

