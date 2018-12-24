# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def can_access?(this)
    controller.can_access?(this)
  end
  
  
  def crm_url
    ip = controller.request.remote_ip()
    
    if(ip =~ /^192/)
      return "http://" + INTERNAL_IP + "/crm/"
    else
      return "http://" + EXTERNAL_IP + "/crm/"
    end
  end
  
  
  def website_url
    ip = controller.request.remote_ip()
    
    if(ip =~ /^192/)
      return "http://" + INTERNAL_IP + ":3000/"
    else
      return "http://" + EXTERNAL_IP + ":3000/"
    end
  end
  
  
  def date_of_file(f)
  # Date formatting of attachment files
    f.strftime "%d/%m/%Y %I:%M:%S %p"
  end
  
  
  def size_of_file(f)
  # Size formatting of attachment files
    number_to_human_size(f)
  end
  
  
  def format_date(d)
    if d.nil?
      return ""
    else
      d.strftime "%d/%m/%Y %I:%M %p"
    end
  end
  
  
  def format_short_date(d)
    if d.nil?
      return ""
    else
      return d.strftime("%d/%m/%Y")
    end
  end
  
  
  def format_price(p)
    controller.format_price(p)
  end
  
  
  def format_report_price(p)
    controller.format_report_price(p)
  end
  
  
  def crm_currency(c)
    (c == CRM_CURRENCY_SOLES ? "S/." : "$")
  end
  
  
  def currency(c)
    controller.currency(c)
  end
  
  
  def verbose_odt_price(p)
    controller.verbose_odt_price(p)
  end
  
  
  def verbose_odt_original_price(p)
    controller.verbose_odt_original_price(p)
  end
  
  
  def state_image(s)
  # Returns an image HTML for "1" and "0" values of a state-based value
    if s == "1"
      image_tag "stock_ok-16.gif", :alt => "SI"
    else
      image_tag "stock_cancel-16.gif", :alt => "NO"
    end
  end
  
  
  def is_executive?
    controller.is_executive?
  end
  
  
  def is_chief_designer?
    controller.is_chief_designer?
  end
  
  
  def is_designer?
    controller.is_designer?
  end
  
  
  def is_costs?
    controller.is_costs?
  end
  
  
  def is_chief_planning?
    controller.is_chief_planning?
  end
  
  
  def is_planner?
    controller.is_planner?
  end
  
  
  def is_operations?
    controller.is_operations?
  end
  
  
  def is_facturation?
    controller.is_facturation?
  end
  
  
  def is_admin?
    controller.is_admin?
  end
  
  
  def is_supervisor?
    controller.is_supervisor?
  end
  
  
  def is_chief_development?
    controller.is_chief_development?
  end
  
  
  def is_development?
    controller.is_development?
  end
  
  
  def is_installations?
    controller.is_installations?
  end
  
  
  def is_operations_validator?
    controller.is_operations_validator?
  end
  
  
  def is_printviewer?
    controller.is_printviewer?
  end
  
  
  def is_owner?
    return controller.is_owner?
  end
  
  
  def format_new_factura_number(number, odt)
    s = number.to_s.rjust(9, "0")
    return EMPRESA_VENDEDORA_SHORT[odt.empresa_vendedora] + "-" + s[0..2] + "-" + s[3..-1]
  end
  
  
  def format_new_guia_number(serie, number)
    return serie.to_s.rjust(3, "0") + "-" + number.to_s.rjust(6, "0")
  end
  
  
  def format_new_factura_number_by_empresa(number, empresa)
    s = number.to_s.rjust(9, "0")
    return EMPRESA_VENDEDORA_SHORT[empresa] + "-" + s[0..2] + "-" + s[3..-1]
  end
  
  
  def format_new_note_number(number, factura)
    s = number.to_s.rjust(9, "0")
    return EMPRESA_VENDEDORA_SHORT[factura.empresa] + "-" + s[0..2] + "-" + s[3..-1]
  end
  
  
  def format_factura_number(factura)
    factura.formatted_factura_number
  end
  
  
  def filter_empty?(section)
    return controller.filter_empty?(section)
  end
  
  
  def autocomplete_account_field(value)
  # The ajaxy autocomplete thing
    html = text_field_with_auto_complete(:account, :name, :value => value)
    
    return html
  end
  
  
  def calendar_hour_clear_button(date, hour)
    return "<input type=\"image\" onclick=\"this.form.#{date}.value=''; this.form.#{hour}.value=''; return false\" src=\"/images/stock_delete-16.gif\" border=\"0\">"
  end
  
  
  def calendar_clear_button(date)
    return "<input type=\"image\" onclick=\"this.form.#{date}.value=''; return false\" src=\"/images/stock_delete-16.gif\" border=\"0\">"
  end
  
  
  def calendar_field(form, id, options = {})
    pre = form.send(id)
    
    if pre.nil?
      value = ""
    else
      value = pre
    end
    
    suffix = options[:suffix] || ""
    
    html = '<input type="text" id="' + id + suffix + '" name="' + id + suffix + '" value="' + value + '" size="8" readonly="true">' + image_tag("calendar.gif", :id => "trigger_#{id}#{suffix}", :border => 0) 
    
    unless options[:no_clear_button]
      html += calendar_clear_button(id + suffix)
    end
    
    html += "<br>\n" + form.e(id)
    return html
  end
  
  
  def calendar_field_with_time(form, name, options = {})
  # Parameters:
  #   form is the Fionna object
  #   name is the form items prefix to use. You'll need three items:
  #   {name}_fecha, {name}_hora and {name}_hora_am_pm
    
    suffix = options[:suffix] || ""
    
    d = name.to_s + "_fecha"
    h = name.to_s + "_hora"
    a = name.to_s + "_am_pm"
    
    html ="
<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">
<tr><td valign=\"top\">

<br>
" + calendar_field(form, d, options) + "

</td><td valign=\"top\" width=\"10\">
</td><td valign=\"top\">

<span class=\"weak\">Formato: hhmm. Ej: 0900, 1130</span><br>
<input type=\"text\" name=\"#{h}#{suffix}\" maxlength=\"4\" size=\"4\" value=\"#{form.send h}\">
<select name=\"#{a}#{suffix}\">
" + form.options_for(a) + "
</select>
" + form.e(h) + "

</td></tr>
</table>
<br>
"
    return html
  end
  
  
  def calendar_javascripts(ids)
    html = '<script type="text/javascript">' + "\n"
    ids.each do |id|
      html += 'Calendar.setup({
    inputField : "' + id + '",
    ifFormat   : "%d/%m/%y",
    button     : "trigger_' + id + '"
});' + "\n"
    end
    html += "</script>"
    
    return html
  end
  
  
  def linked_list_of_odts(list)
    html = ""
    
    list.each do |o|
      html += link_to(o, :controller => "projects", :action => "show", :id => o, :type => "o") + "<br>\n"
    end
    
    return html
  end
  
  
  def render_form_range_date(form, sm, sy, em, ey)
    html = "<select name=\"#{sm.to_s}\" id=\"#{sm.to_s}\" onChange=\"relay(this, '#{em.to_s}')\">
#{form.options_for sm}
</select>
<select name=\"#{sy.to_s}\" id=\"#{sy.to_s}\" onChange=\"relay(this, '#{ey.to_s}')\">
#{form.options_for sy}
</select>

a

<select name=\"#{em.to_s}\" id=\"#{em.to_s}\">
#{form.options_for em}
</select>
<select name=\"#{ey.to_s}\" id=\"#{ey.to_s}\">
#{form.options_for ey}
</select><br>

#{form.e sm}
#{form.e sy}
#{form.e em}
#{form.e ey}
"
    return html
  end
  
  
  def overlib(msg)
    return "onmouseover=\"return overlib('#{msg}', DELAY, 1000, FOLLOWMOUSE, 0);\" onmouseout=\"nd();\""
  end
  
  
  def overlib_as_hash(msg)
    return { :onmouseover => "return overlib('#{msg}', DELAY, 1000, FOLLOWMOUSE, 0)", :onmouseout => "nd();" }
  end
  
  
  def calculate_days (ingreso, salida)
    if salida.nil?
      return (Time.now.strftime("%j").to_i + Time.now.strftime("%Y").to_i) - (ingreso.strftime("%j").to_i + ingreso.strftime("%Y").to_i)
    else
      return (salida.strftime("%j").to_i + salida.strftime("%Y").to_i) - (ingreso.strftime("%j").to_i + ingreso.strftime("%Y").to_i)
    end
  end
  
  
  def can_see_company?(c)
    return controller.can_see_company?(c)
  end
  
  
  def in_development?
    return ENV['RAILS_ENV'] == "development"
  end
  
  
  def render_pages_list(action)
    parameters = {
      :action => action,
      :tab    => controller.current_tab
    }
    
    html = "<span class=\"panel_pages\"><center>"
    
    unless @page == 1
      parameters[:page] = 1
      html += link_to("Inicio", parameters) + " - "
      
      parameters[:page] = @page - 1
      html += link_to("Anterior", parameters) + " - "
    else
      html += "Inicio - Anterior - "
    end
    
    if @total_pages > 20
      startp = @page - 10
      startp = 1 if startp < 1
      
      endp = startp + 19
      if endp > @total_pages
        endp   = @total_pages
        startp = endp - 19
      end
    else
      startp = 1
      endp   = @total_pages
    end
    
    startp.upto endp do |i|
      if @page == i
        html += "<b>#{i}</b>"
      else
        parameters[:page] = i
        html += link_to i, parameters
      end
      
      html += " - "
    end
    
    unless @page == @total_pages
      parameters[:page] = @page + 1
      html += link_to("Siguiente", parameters)
      
      parameters[:page] = @total_pages
      html += " - " + link_to("Fin", parameters)
    else
      html += "Siguiente - Fin"
    end
    
    html += "</center></span><br>"
    
    return html
  end
  
  
  def panel_header_as_html(field)
    if field.sortable?
      if field.type == @order[:field]
        link_class = "panel_field_selected"
      else
        link_class = "panel_field_names"
      end
      
      str = link_to field.name, { :controller => "projects", :action => "set_sort_field", :tab => @tab, :field => field.type }, :class => link_class
    else
      str = '<span class="panel_field_names">' + field.name + '</span>'
    end
    
    return str
  end
  
  
end

