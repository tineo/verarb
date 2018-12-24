# Fionna on Rails v1.1.0
# A fine piece of junk written by Jaime G. Wong <j@jgwong.org>
# Based on concepts by Antonio "gnrfan" Ognio <gnrfan@gnrfan.org>
#
# Copyright © 2003-2008 Jaime G. Wong <j@jgwong.org>
# Permission to use, copy, modify, distribute, and sell this software and its
# documentation for any purpose is hereby granted without fee, provided that
# the above copyright notice appear in all copies and that both that
# copyright notice and this permission notice appear in supporting
# documentation.  No representations are made about the suitability of this
# software for any purpose. It is provided "as is" without express or 
# implied warranty.
#
# Historic changes (please note your changes here):
#
# 20060929 jaime g. wong <j@jgwong.org>
# - Porting from the PHP version of Fionna to RoR.
#
# 20061118 jaime g. wong <j@jgwong.org>
# - Now we can set values directly via Fionna#element = value
# - New methods: set_property_of, set_error_msg_of, get_property_of
#
# 20061127 jaime g. wong <j@jgwong.org>
# - Bugfix on empty elements being tested for validation
#
# 20070519 jaime g. wong <j@jgwong.org>
# - Added an elements_with_errors method for debugging purposes. It's an array
#   which enumerates the elements which had validation errors.
# 
# 20070731 jaime g. wong <j@jgwong.org>
# - Modified behavior of checkboxes. Now by default its values are "0" and "1"
#   for unset and set values. If there's data on the POST params, then it
#   automatically assigns the set_value. If there isn't or the unset value is
#   on the POST param, then it is assigned the unset_value.
#   This change was made so we can load variables directly from the DB and have
#   unset values handled correctly, instead of casting them to nil.
#
# 20070814 jaime g. wong <j@jgwong.org>
# - Bugfix on set_error_msg_for
# 
# 20070823 jaime g. wong <j@jgwong.org>
# - Same hack previously noted when we assign directly to a checkbox.
#   i.e. @form.active = @task.active
#   I'd like to rephrase the workings of a checkbox: it's basically a boolean
#   but you can setup what value it will contain for "true" and "false" states
#   on the set_value and unset_value properties.
#   A checkbox will be set to its set_value if the value given is non-nil
#   or is the same value as the set_value property.
#   A checkbox will be set to its unset_value if the value given is nil
#   or is the same value as the unset_value property.
# 
# 20080202 jaime g. wong <j@jgwong.org>
# - You can now load a value to a date with a Time object.
# 
# 20080222 jaime g. wong <j@jgwong.org>
# - A max_length of 65535 is hardcoded to acts_as textarea text items. Gotta
#   find a better way to handle that.
# 
# 20080311 jaime g. wong <j@jgwong.org>
# - Fixed regexp which raised warnings on recent version of Rails.
# - Fixed hardcoding of acts_as textarea
# 
# 20080812 jaime g. wong <j@jgwong.org>
# - Fixed emptyness check for Radios.
# - get_property_of and set_property_of will automagically convert the
#   parameters to string. Me and a bad habit of using symbols.
# 
# 20080918 jaime g. wong <j@jgwong.org>
# - Changed E-Mail regexp in favor of Cal Henderson's one. Pretty nifty.
# 

class Fionna
  include Reloadable
  alias :method_missing_orig :method_missing
  
  
  def initialize(form)
    @error_count          = 0
    @elements_with_errors = []
    
    begin
      vars = YAML::load(File.open(RAILS_ROOT + '/app/forms/' + form + '.yaml'))
    rescue
      raise "Fionna: Error reading form definition '" + form + "'. File not found or invalid syntax."
    end
    
    if vars.nil? || vars == false || vars.empty?
      raise "Fionna: undefined definition or empty"
    end
    
    # We check if an element name is not conflicting with an existing
    # class method
    vars.each do |element, v|
      if self.respond_to?(element)
        raise "Fionna: element name '" + element + "' causes conflict"
      end
    end
    
    @vars = vars
    
    load_default_values
  end
  
  
  def load_default_values
    # Default values for every type
    defaults = {
      'type'       => 'text',
      'validate'   => true,
      'mandatory'  => true,
      'show_value' => true,
      'show_error' => true,
      'min_length' => 0,
      'empty_msg'  => 'Debes especificar un valor',
      'error_msg'  => '',
      'value'      => '',
    }
    
    # Default functions according to type
    functions = {
      'text'          => 'validate_dummy',
      'select'        => 'validate_select',
      'selectbox'     => 'validate_selectbox',
      'checkbox'      => 'validate_checkbox',
      'checkboxmulti' => 'validate_checkboxmulti',
      'radio'         => 'validate_radio',
      'date'          => 'validate_date'
    }
    
    @vars.each do |item, values|
      @vars[item].reverse_merge! defaults
      
      # Set default function
      @vars[item]['function'] ||= functions[@vars[item]['type']]
      
      # Set default max/min length message
      @vars[item]['max_length_msg'] ||= 'No debe exceder ' + @vars[item]['max_length'].to_s + ' caracteres'
      @vars[item]['min_length_msg'] ||= 'Debe contener al menos ' + @vars[item]['min_length'].to_s + ' caracteres'
      
      # And now we set defaults according to type
      type = @vars[item]['type']
      
      if type == 'text'
        @vars[item]['acts_as'] ||= "text"
        
        @vars[item]['value']   ||= ""
        @vars[item]['filters'] ||= ["filter_strip", "filter_strip_tags"]
      
      elsif type == 'select'
        @vars[item]['unset_option'] ||= nil
        @vars[item]['options']      ||= item + "_options"
        @vars[item]['value']        ||= @vars[item]['unset_option']
      
      elsif type == 'selectbox'
        @vars[item]['options']      ||= item + "_options"
      
      elsif type == 'checkbox'
        @vars[item]['set_value']   ||= "1"
        @vars[item]['unset_value'] ||= "0"
        @vars[item]['checked']     ||= false
        @vars[item]['value']       ||= "0"
      
      elsif type == 'checkboxmulti'
        @vars[item]['options'] ||= item + "_options"
        @vars[item]['value']   ||= []
      
      elsif type == 'radio'
        @vars[item]['options'] ||= item + "_options"
        @vars[item]['value']   ||= ""
      
      elsif type == 'date'
        @vars[item]['d_options'] ||= "fionna_day_options"
        @vars[item]['m_options'] ||= "fionna_month_options"
        @vars[item]['y_options'] ||= "fionna_year_options"
        @vars[item]['d']         ||= nil
        @vars[item]['m']         ||= nil
        @vars[item]['y']         ||= nil
        @vars[item]['value']     ||= nil
      end
      
      # Set max_length size
      if type == 'text' && @vars[item]['acts_as'] == 'textarea'
        @vars[item]['max_length'] ||= 65535
      else
        @vars[item]['max_length'] ||= 512
      end
    end
    
    
  end
  
  
  def load_values(p)
    @vars.each do |element, values|
      ve = element.to_s
      if @vars[ve]['type'] == "checkbox"
        if p[element].nil?
          @vars[ve]['value'] = @vars[ve]['unset_value']
          @vars[ve]['checked'] = false
        elsif p[element].to_s == @vars[ve]['unset_value']
          @vars[ve]['value'] = @vars[ve]['unset_value']
          @vars[ve]['checked'] = false
        else
          @vars[ve]['value'] = @vars[ve]['set_value']
          @vars[ve]['checked'] = true
        end
      
      elsif @vars[ve]['type'] == "checkboxmulti"
        if p[element].class.to_s == "Array"
          @vars[ve]['value'] = p[element]
        else
          @vars[ve]['value'] = []
        end
      
      elsif @vars[ve]['type'] == "selectbox"
        if p[element].class.to_s == "Array"
          @vars[ve]['value'] = p[element]
        else
          @vars[ve]['value'] = []
        end
      
      elsif @vars[ve]['type'] == "date"
        if p.has_key?(element) && p[element].class.to_s == "Time"
          @vars[ve]['d'] = p[element].strftime("%d").to_i.to_s
          @vars[ve]['m'] = p[element].strftime("%m").to_i.to_s
          @vars[ve]['y'] = p[element].strftime("%Y").to_i.to_s
          # .to_i.to_s because we want "1" not "01"
        else
          ["d", "m", "y"].each do |e|
            if p.has_key?(element + "_" + e)
              @vars[ve][e] = p[element + "_" + e].to_s
            else
              @vars[ve][e] = nil
            end
          end
        end
        
        process_date!(element)
      
      elsif p.has_key?(element)
        @vars[ve]['value'] = p[element].to_s
      else
      end
    end
  end
  
  
  def valid?
    valid         = true
    current_valid = true
    
    @vars.each do |element, values|
      # Run filters
      unless @vars[element]['filters'].nil?
        @vars[element]['filters'].each do |f|
          @vars[element]['value'] = send(f, @vars[element]['value'])
        end
      end
      
      value = values['value']
      type  = values['type']
      
      current_valid = true
      
      # Check for emptyness
      empty = false
      
      if mandatory?(element) && empty?(element)
        empty = true
      end
      
      if (empty)
        @vars[element]['error_msg'] = values['empty_msg']
        valid         = false
        current_valid = false
      end
      
      # Check for lengths
      if valid && values['max_length'] > 0 && value.to_s.length > values['max_length']
        @vars[element]['error_msg'] = values['max_length_msg']
          valid         = false
          current_valid = false
      end
      
      if valid && values['min_length'] > 0 && value.to_s.length < values['min_length']
        @vars[element]['error_msg'] = values['min_length_msg']
          valid         = false
          current_valid = false
      end
      
      # Call the validation function and see if we got back an error
      # message
      if current_valid && !empty?(element)
        error = send(values['function'], element, value)
        
        unless error == ''
          @vars[element]['error_msg'] = error
          valid         = false
          current_valid = false
          
          if ENV['RAILS_ENV'] == 'test'
            raise element
          end
        end
      end
      
      # Finally, if the element was invalid, we count it
      @error_count += 1 unless current_valid
      
      @elements_with_errors << element unless current_valid
    end
    
    return valid
  end
  
  
  def method_missing(methId, *args)
    id = methId.id2name
    
    if id =~ /^(.+?)=$/
      if @vars[$1]['type'] == "checkbox"
        ve = $1
        
        if args[0].nil?
          @vars[ve]['value'] = @vars[ve]['unset_value']
          @vars[ve]['checked'] = false
        elsif args[0].to_s == @vars[ve]['unset_value']
          @vars[ve]['value'] = @vars[ve]['unset_value']
          @vars[ve]['checked'] = false
        else
          @vars[ve]['value'] = @vars[ve]['set_value']
          @vars[ve]['checked'] = true
        end
      else
        @vars[$1]['value'] = args[0]
      end
    elsif @vars.has_key?(id)
      @vars[id]['value']
    else
      method_missing_orig(methId, *args)
    end
  end
  
  
  def e(element)
    # Renders an element's error message, to be used in a View context
    element = element.to_s
    
    if @vars[element]['error_msg'] == ""
      ""
    elsif @vars[element]['show_error']
      '<span class="error_msg">' + @vars[element]['error_msg'] + '</span><br>'
    else
      ""
    end
  end
  
  
  def get_property_of(element, property)
    element  = element.to_s
    property = property.to_s
    @vars[element][property]
  end
  
  
  def set_property_of(element, properties)
    element = element.to_s
    
    p = {}
    properties.each do |k, v|
      p[k.to_s] = v
    end
    
    @vars[element].merge! p
  end
  
  
  def set_error_msg_of(element, msg)
    self.set_property_of element, { "error_msg" => msg }
  end
  
  
  def empty?(element)
    # Checks for emptyness, according to an element's type
    empty = false
    
    t = @vars[element]['type']
    v = @vars[element]['value']
    
    if t == 'text' &&  v == ''
      empty = true
    
    elsif t == 'select'
      if @vars[element]['unset_option'] != nil && v.to_s == @vars[element]['unset_option'].to_s
        empty = true
      end
    
    elsif t == 'selectbox'
      if v.size == 0
        empty = true
      end
    
    elsif t == 'checkboxmulti'
      if v.size == 0
        empty = true
      end
    
    elsif t == 'date'
      this = @vars[element]
      
      if this['d'] == nil && this['m'] == nil && this['y'] == nil
        empty = true
      end
      
      if this['d'] == "-1" && this['m'] == "-1" && this['y'] == "-1"
        empty = true
      end
    
    elsif t == 'radio'
      o = get_options(element)
      empty = !(o.has_key? v)
    end
    
    return empty
  end
  
  
  def mandatory?(element)
    @vars[element]['mandatory']
  end
  
  
  def elements_with_errors
    @elements_with_errors
  end
  
  
  def get_values
    r = {}
    
    @vars.each do |element, values|
      r[element] = values['value']
    end
    
    return r
  end
  
  
  def error_count
    @error_count
  end
  
  
  def get_options(element)
    if @vars[element]['options'].class.to_s == 'Hash' || @vars[element]['options'].class.to_s == 'OHash'
      @vars[element]['options']
    elsif @vars[element]['options'].class.to_s == 'String'
      send(@vars[element]['options'])
    end
  end
  
  
  def options_for(element)
    element = element.to_s
    unless @vars[element]['type'] == 'select'
      return ""
    end
    
    opt = get_options(element)
    
    html = ""
    
    opt.each do |k, v|
      html += '<option value="' + k.to_s + '"' + (@vars[element]['value'].to_s == k.to_s ? ' selected' : '') + '>' + v.to_s + "</option>\n"
    end
    
    return html
  end
  
  
  def label_for(element)
    element = element.to_s
    
    unless @vars[element]['type'] == 'select' || @vars[element]['type'] == 'radio'
      return nil
    end
    
    opt = get_options(element)
    
    return opt[@vars[element]['value']]
  end
  
  
  def labels_for(element)
    element = element.to_s
    
    unless @vars[element]['type'] == 'checkboxmulti' || @vars[element]['type'] == 'selectbox'
      return nil
    end
    
    opt = get_options(element)
    
    r = []
    
    @vars[element]['value'].each do |v|
      r << opt[v]
    end
    
    return r
  end
  
  
  def to_html(element, options = {})
    options.reverse_merge!({
      :class              => nil,
      :size               => 40,
      :cols               => 40,
      :rows               => 5,
      :hide_error_message => nil,
      :boxsize            => 4
    })
    
    element = element.to_s
    
    type = @vars[element]['type']
    
    if options[:class]
      class_html = " class=\"#{options[:class_html]}\""
    else
      class_html = ""
    end
    
    if type == "text"
      acts_as = @vars[element]['acts_as']
      
      if acts_as == 'text'
        html = "<input type=\"text\" name=\"#{element}\" value=\"" + send(element) + "\" size=\"#{options[:size]}\" maxlength=\"#{@vars[element]['max_length']}\"" + class_html + ">"
      
      elsif acts_as == 'textarea'
        html = "<textarea name=\"#{element}\" cols=\"#{options[:cols]}\" rows=\"#{options[:rows]}\"" + class_html + ">" + send(element) + "</textarea>"
      
      elsif acts_as == 'password'
        html = "<input type=\"password\" name=\"#{element}\" value=\"\" size=\"#{options[:size]}\" maxlength=\"#{@vars[element]['max_length']}\"" + class_html + ">"
      end
    
    elsif type == "select"
      html = "<select name=\"#{element}\"" + class_html + ">\n" + options_for(element) + "</select>"
    
    elsif type == "selectbox"
      html = "<select name=\"#{element}[]\" multiple=\"yes\" size=\"#{options[:boxsize]}\"" + class_html + ">\n"
      
      opt = get_options(element)
      
      opt.each do |k, v|
        html += '<option value="' + k + '"' + (@vars[element]['value'].include?(k) ? ' selected' : '') + '>' + v + "</option>\n"
      end
      
      html += "</select>"
    
    elsif type == "checkbox"
      options[:hide_error_message] = true
      html = "<input type=\"checkbox\" name=\"#{element}\" value=\"#{@vars[element]['set_value']}\"" + (@vars[element]['checked'] ? ' checked' : '') + class_html + ">"
    
    elsif type == "checkboxmulti"
      if options[:value].nil?
        # We render all the collection
        opt = get_options(element)
        
        html = ""
        
        opt.each do |key, value|
          html = html + "<input type=\"checkbox\" name=\"#{element}[]\" value=\"#{key}\"" + (@vars[element]['value'].include?(key) ? ' checked' : '') + class_html + ">" + value + "<br>\n"
        end
        
        options[:hide_error_message] = true
        html = html + e(element)
        
      else
        # We render just one checkbox
        options[:hide_error_message] = true
        
        if options[:hide_label]
          label = ""
        else
          opt   = get_options(element)
          label = " " + opt[options[:value]]
        end
        
        html = "<input type=\"checkbox\" name=\"#{element}[]\" value=\"#{options[:value]}\"" + (@vars[element]['value'].include?(options[:value]) ? ' checked' : '') + class_html + ">" + label
      end
    
    elsif type == "radio"
      if options[:value].nil?
        # We render all the collection
        opt = get_options(element)
        
        html = ""
        
        opt.each do |key, value|
          html = html + "<input type=\"radio\" name=\"#{element}\" value=\"#{key}\"" + (@vars[element]['value'] == key ? ' checked' : '') + class_html + "> " + value + "<br>\n"
        end
        
        options[:hide_error_message] = true
        html = html + e(element)
        
      else
        # We render just one radio
        options[:hide_error_message] = true
        
        if options[:hide_label]
          label = ""
        else
          opt   = get_options(element)
          label = " " + opt[options[:value]]
        end
        
        html = "<input type=\"radio\" name=\"#{element}\" value=\"#{options[:value]}\"" + (@vars[element]['value'] == options[:value] ? ' checked' : '') + class_html + ">" + label
      end
      
    elsif type == "date"
      od = send(@vars[element]['d_options'])
      om = send(@vars[element]['m_options'])
      oy = send(@vars[element]['y_options'])
      
      html = ""
      
      # Days
      html += "<select name=\"#{element}_d\">\n"
      od.each do |key, value|
        html += "<option value=\"#{key}\"" + (@vars[element]['d'] == key ? ' selected' : '') + ">#{value}</option>\n"
      end
      html += "</select>\n"
      
      # Months
      html += "<select name=\"#{element}_m\">\n"
      om.each do |key, value|
        html += "<option value=\"#{key}\"" + (@vars[element]['m'] == key ? ' selected' : '') + ">#{value}</option>\n"
      end
      html += "</select>\n"
      
      # Years
      html += "<select name=\"#{element}_y\">\n"
      oy.each do |key, value|
        html += "<option value=\"#{key}\"" + (@vars[element]['y'] == key ? ' selected' : '') + ">#{value}</option>\n"
      end
      html += "</select>\n"
    end
    
    # We append the error message at the end automagically
    unless options[:hide_error_message]
      html = html + "<br>\n" + e(element)
    end
    
    return html
  end
  
  
  def process_date!(element)
    # Processes the individual values of a element of type date to a Date
    # object
    begin
      @vars[element]['value'] = Date::parse(@vars[element]['y'] + "-" +  @vars[element]['m'] + "-" + @vars[element]['d'])
    rescue
      @vars[element]['value'] = nil
    end
  end
  
  # Standard validation functions
  
  def validate_dummy(var, val)
    return ""
  end
  
  
  def validate_select(var, val)
    opt = get_options(var)
    
    unless opt.has_key?(val)
      return "Debes seleccionar un elemento de la lista"
    end
    
    if val == @vars[var]['unset_option']
      return "Debes seleccionar un elemento de la lista"
    end
    
    return ""
  end
  
  
  def validate_selectbox(var, val)
    opt = get_options(var)
    
    val.each do |v|
      unless opt.has_key?(v)
        return "Debes seleccionar un elemento de la lista"
      end
    end
    
    return ""
  end
  
  
  def validate_checkbox(var, val)
    return ""
  end
  
  
  def validate_checkboxmulti(var, val)
    opt = get_options(var)
    
    val.each do |v|
      unless opt.has_key?(v)
        return "Debes seleccionar un elemento de la lista"
      end
    end
    
    return ""
  end
  
  
  def validate_radio(var, val)
    opt = get_options(var)
    
    unless opt.has_key?(val)
      return "Debes seleccionar un elemento de la lista"
    end
    
    return ""
  end
  
  
  def validate_date(var, val)
    this = @vars[var]
    
    od = send(@vars[var]['d_options'])
    om = send(@vars[var]['m_options'])
    oy = send(@vars[var]['y_options'])
    
    if this['d'].nil? || this['d'] == "-1"
      return "Debes seleccionar un d&iacute;a"
    end
    
    if this['m'].nil? || this['m'] == "-1"
      return "Debes seleccionar un mes"
    end
    
    if this['y'].nil? || this['y'] == "-1"
      return "Debes seleccionar un a&ntilde;o"
    end
    
    process_date!(var)
    
    if this['value'].nil?
      return "La fecha es inv&aacute;lida"
    end
    
    # In lists?
    
    return ""
  end
  
  
  def validate_doppleganger(var, val)
    unless val == @vars[@vars[var]['element']]['value']
      @vars[var]['invalid_msg'] || "Los campos no coinciden"
    else
      ""
    end
  end
  
  
  def validate_name(var, val)
    unless val =~ /^[a-zA-Z·ÈÌÛ˙¡…Õ”⁄Ò—\'‰ÎÔˆ¸ƒÀœ÷‹ \-\.]+$/
      "Debes ingresar un nombre v&aacute;lido"
    else
      ""
    end
  end
  
  
  def validate_number(var, val)
    unless val =~ /^[0-9]+$/
      "Debes ingresar un n&uacute;mero v&aacute;lido"
    else
      ""
    end
  end
  
  
  def validate_email(var, val)
    # Originally written by Cal Henderson
    # c.f. http://iamcal.com/publish/articles/php/parsing_email/
    #
    # Translated to Ruby by Tim Fletcher, with changes suggested by Dan Kubb.
    #
    # Licensed under a Creative Commons Attribution-ShareAlike 2.5 License
    # http://creativecommons.org/licenses/by-sa/2.5/
    # 
    # http://tfletcher.com/lib/rfc822.rb
    qtext          = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
    dtext          = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
    atom           = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' + '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
    quoted_pair    = '\\x5c[\\x00-\\x7f]'
    domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
    quoted_string  = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
    domain_ref     = atom
    sub_domain     = "(?:#{domain_ref}|#{domain_literal})"
    word           = "(?:#{atom}|#{quoted_string})"
    domain         = "#{sub_domain}(?:\\x2e#{sub_domain})*"
    local_part     = "#{word}(?:\\x2e#{word})*"
    addr_spec      = "#{local_part}\\x40#{domain}"
    email_regexp   = /\A#{addr_spec}\z/
    
    unless val =~ email_regexp
      "La direcci&oacute;n de correo es inv&aacute;lida"
    else
      ""
    end
  end
  
  
  def validate_username(var, val)
    unless val =~ /^[_a-z]+([_a-z0-9]+)*\$/
      return "Nombre de usuario contiene caracteres inv&aacute;lidos o no empieza con una letra"
    end
    
    if val.length < 4
      return "Debe contener al menos 4 caracteres"
    end
    
    return ""
  end
  
  
  def validate_precio(var, val)
    # Un precio es un numero asÌ: 32, 32.50, 32.5, 32.00
    unless val =~ /^[0-9]+(\.[0-9]{1,3}){0,1}$/
      "Debe ingresar un precio v&aacute;lido (ej: 32, 16.20, 8.5)"
    else
      ""
    end
  end
  
  
  # Default filters
  
  def filter_strip(val)
    return val.strip
  end
  
  
  def filter_strip_tags(val)
    return val.gsub(/<\/?[^>]*>/, "")
  end
  
  # Default lists
  
  def fionna_day_options
    a = OHash::new
    a["-1"] = "[D&iacute;a]"
    31.times do |d|
      d = (d + 1).to_s
      a[d] = d
    end
    
    return a
  end
  
  
  def fionna_month_options
    a = OHash::new
    
    a["-1"] = "[Mes]"
    12.times do |d|
      d = (d + 1)
      a[d.to_s] = Date::MONTHNAMES[d]
    end
    
    return a
  end
  
  
  def fionna_year_options
    a = OHash::new
    a["-1"]               = "[A&ntilde;o]"
    a[Time.now.year.to_s] = Time.now.year.to_s
    return a
  end
end


class OHash < Hash
  alias_method :store, :[]=
  alias_method :each_pair, :each

  def initialize
          @keys = []
  end

  def []=(key, val)
          @keys << key
          super
  end

  def delete(key)
          @keys.delete(key)
          super
  end

  def each
    @keys.each { |k| yield k, self[k] }
  end

  def each_key
    @keys.each { |k| yield k }
  end

  def each_value
    @keys.each { |k| yield self[k] }
  end
end


load RAILS_ROOT + '/app/forms/application.rb'

