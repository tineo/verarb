module ReportsHelper
  def render_exec_report_sort_field (label, index, sort_param, dir_param)
    if params[sort_param] == index.to_s
      classn = "panel_field_selected"
      
      if params[dir_param] == "0"
        direction = "1"
      else
        direction = "0"
      end
    else
      classn = "panel_field"
    end
    
    # Generate the URL preserving the parameters
    parameters              = request.parameters.clone
    parameters[:controller] = "reports"
    parameters[:action]     = "ventas"
    parameters[sort_param]  = index
    parameters[dir_param]   = direction
    
    link_to label, parameters, :class => classn
  end
  
  
  def render_quota_sort_field (label, sort_param, dir_param)
    if params[sort_param] == label[1]
      classn = "panel_field_selected"
      
      if params[dir_param] == "0"
        direction = "1"
      else
        direction = "0"
      end
    else
      classn = "panel_field"
    end
    
    # Generate the URL preserving the parameters
    url              = request.parameters.clone
    url[:controller] = "reports"
    url[:action]     = "executives_quotas"
    url[sort_param]  = label[1]
    url[dir_param]   = direction
    
    options = { :class => classn }
    options.merge!(overlib_as_hash("En los casos de Cobranzas Largas se asume como cobrado para la Comisi&oacute;n")) if label[1] == "billed"
    
    return link_to(label[0], url, options)
  end
  
  
  def render_design_report_sort_field (label, index, sort_param, dir_param)
    if params[sort_param] == index.to_s
      classn = "panel_field_selected"
      
      if params[dir_param] == "0"
        direction = "1"
      else
        direction = "0"
      end
    else
      classn = "panel_field"
    end
    
    # Generate the URL preserving the parameters
    parameters              = request.parameters.clone
    parameters[:controller] = "reports"
    parameters[:action]     = "design"
    parameters[sort_param]  = index
    parameters[dir_param]   = direction
    
    link_to label, parameters, :class => classn
  end
  
  
  def truput_header_with_help(header, help)
  # Renders a header of the Truput (and Cierre de Ventas) report with
  # an OverLib help
    return "<a href=\"javascript:void(0);\" " + overlib(help) + " class=\"truput_header\">#{header}</a>"
  end
  
  
  def render_sort_field (field, controller, action, sort_param, dir_param)
    return "<span class=\"panel_field\">#{field[0]}</span>" if field[1] == ""
    
    if params[sort_param] == field[1]
      classn = "panel_field_selected"
      
      if params[dir_param].nil?
        direction = "0"
      end
      
      if params[dir_param] == "0"
        direction = "1"
      else
        direction = "0"
      end
    else
      classn    = "panel_field"
      direction = "0"
    end
    
    # Generate the URL preserving the parameters
    parameters              = request.parameters.clone
    parameters[:controller] = controller
    parameters[:action]     = action
    parameters[sort_param]  = field[1]
    parameters[dir_param]   = direction
    
    link_to field[0], parameters, :class => classn
  end
  
  
end
