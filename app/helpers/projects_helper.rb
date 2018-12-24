module ProjectsHelper
  def render_attribute(attr, index)
    name  = "attr" + index.to_s
    value = attr.valor
    
    # TEXTO LIBRE
    if attr.tipo == 'txt'
      html = '<input type="text" name="' + name + '" value="' + value + '" size="30" maxlength="65535">'
    
    # NUMERO
    # Este es el único que tiene validación
    elsif attr.tipo == 'num'
      html = '<input type="text" name="' + name + '" value="' + value + '" size="30" maxlength="65535">'
      
      unless attr.valid?
        html = html + "<br><span class=\"error_msg\">Debes ingresar un n&uacute;mero v&aacute;lido</span>"
      end
    
    # COMMENT BOX (TEXTAREA)
    elsif attr.tipo == 'com'
      html = '<textarea name="' + name + '" cols="30" rows="10">' + "\n" + value + "\n</textarea>"
    
    # CHECKBOX
    elsif attr.tipo == 'chk'
      if value == ""
        checked = ""
      else
        checked = "checked"
      end
      
      html = '<input type="checkbox" name="' + name + '" value="1" ' + checked + '>'
    elsif attr.tipo == 'sep'
      html = '&nbsp;'
    end
    
    return html
  end
  
  
  def image_for_detail(d)
    image = d.get_image
    
    if image == ""
      return "&nbsp;"
    else
      return '<center>
    <img src="' + url_for(:controller => "projects", :action => "get_file", :id => @project.uid, :type => @project.type, :did => d.id, :fid => image, :print => 1, :escape => false) + '">
    </center>'
    end
  end
  
  
  def image_for_product(p)
    image = p.get_image
    
    if image == ""
      return "&nbsp;"
    else
      return '<center>
    <img src="' + url_for(:controller => "products", :action => "get_file", :pid => p.id, :fid => image, :print => 1, :escape => false) + '">
    </center>'
    end
  end
  
  
  def image_for_display_product(p)
    image = p.get_image
    
    if image == ""
      return "&nbsp;"
    else
      return '<center>
    <img src="' + url_for(:controller => "products", :action => "get_file", :pid => p.id, :fid => image.filename, :display => 1, :escape => false) + '">
    </center>'
    end
  end
  
  
end
