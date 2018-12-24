class Fionna
  def empresa_vendedora_options
    r = OHash.new
    
    r["-1"] = "[Elija una empresa]"
    EMPRESA_VENDEDORA.each_with_index do |n, i|
      r[i.to_s] = n
    end
    
    return r
  end
  
  
  def tipo_de_venta_options
    r = OHash.new
    
    r["-1"] = "[Elija un tipo]"
    TIPO_DE_VENTA.each_with_index do |n, i|
      r[i.to_s] = n
    end
    
    return r
  end
  
  
  def client_options
    clients = Account.find :all, "deleted='0'", :order => :name
    
    if clients.nil?
      false
    else
      r = OHash.new
      
      r["-1"] = "[Elija un cliente]"
      
      clients.each do |c|
        r[c.id.to_s] = c.name
      end
      
      return r
    end
  end
  
  
  def contact_options
    r = OHash.new
    c = @vars["client"]["value"]
    
    unless c == "" || c == "-1"
      contacts = Account.find(c).contacts.find_all_by_deleted("0")
      
      unless contacts.empty?
        r["-1"] = "[Elija un contacto]"
        
        contacts.each do |co|
          r[co.contact_id.to_s] = co.full_name
        end
      else
        r["-1"] = "[Este cliente no tiene contactos]"
      end
    else
      r["-1"] = "[Este cliente no tiene contactos]"
    end
    
    return r
  end
  
  
  def project_type_options
    r = OHash.new
    
    [T_NUEVO_PROYECTO, T_ORDEN_INTERNA, T_OTRO].each do |t|
      r[t.to_s] = TIPO_PROYECTO[t]
    end
    
    return r
  end
  
  
  def subtipo_nuevo_proyecto_options
    r = OHash.new
    
    r[SUBTIPO_NUEVO_PROYECTO_MOBILIARIO.to_s]   = "Mobiliario"
    r[SUBTIPO_NUEVO_PROYECTO_ARQUITECTURA.to_s] = "Proyectos"
    
    return r
  end
  
  
  def validate_textdate(var, val)
    if (val =~ /^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{2})$/) == nil
      "No es un formato de fecha v&aacute;lido"
    else
      a = process_textdate(var)
      
      if a.nil?
        "La fecha es inv&aacute;lida"
      else
        ""
      end
    end
  end
  
  
  def process_textdate(element)
    val = @vars[element.to_s]["value"]
    
    val =~ /^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{2})$/
    
    begin
      Date::parse("20" + $3 + "-" + $2 + "-" + $1)
    rescue
      nil
    end
  end
  
  
  def validate_texttime(var, val)
    if val =~ /^([0-9]{2})([0-9]{2})$/
      return "Hora \"#{$1}\" es incorrecta" if $1.to_i > 12
      return "Minutos \"#{$2}\" es incorrecto" if $2.to_i > 59
      
      return ""
    else
      return "No es un formato de tiempo v&aacute;lido"
    end
  end
  
  
  def hora_am_pm_options
    r = OHash.new
    r["AM"] = "AM"
    r["PM"] = "PM"
    
    return r
  end
  
  
  def nivel_seguridad_options
    r = OHash.new
    NIVEL_SEGURIDAD.each_with_index do |n, i|
      unless n.nil?
        r[i.to_s] = n
      end
    end
    
    return r
  end
  
  
  def como_se_vera_options
    r = OHash.new
    r["FR"] = "Frente"
    r["DE"] = "Derecha"
    r["IZ"] = "Izquierda"
    r["AT"] = "Atr&aacute;s"
    r["AR"] = "Arriba"
    r["AB"] = "Abajo"
    
    return r
  end
  
  
  def categoria_productos_options
    cats = Categoria.of_products
    
    r = OHash.new
    
    r["-1"] = "[Elije una categor&iacute;a]"
    
    cats.each do |c|
      r[c.id.to_s] = c.nombre
    end
    
    return r
  end
  
  
  def categoria_servicios_options
    cats = Categoria.of_services
    
    r = OHash.new
    
    r["-1"] = "[Elije una categor&iacute;a]"
    
    cats.each do |c|
      r[c.id.to_s] = c.nombre
    end
    
    return r
  end
  
  
  def producto_options
    r = OHash.new
    
    unless @vars["categoria"]["value"] == "-1"
      prods = Producto.of_category @vars["categoria"]["value"]
      
      unless prods.empty?
        r["-1"] = "[Elige un producto]"
        
        prods.each do |p|
          r[p.id.to_s] = p.nombre
        end
      else
        r["-1"] = "[Esta categor&iacute;a no tiene productos]"
      end
    else
      r["-1"] = "[Esta categor&iacute;a no tiene productos]"
    end
    
    return r
  end
  
  
  def servicio_options
    r = OHash.new
    
    unless @vars["categoria"]["value"] == "-1"
      servs = Servicio.of_category @vars["categoria"]["value"]
      
      unless servs.empty?
        r["-1"] = "[Elige un servicio]"
        
        servs.each do |p|
          r[p.id.to_s] = p.nombre
        end
      else
        r["-1"] = "[Esta categor&iacute;a no tiene servicios]"
      end
    else
      r["-1"] = "[Esta categor&iacute;a no tiene servicios]"
    end
    
    return r
  end
  
  
  def moneda_options
    r = OHash.new
    
    r["D"] = "D&oacute;lares"
    r["S"] = "Soles"
    
    return r
  end
  
  
  def lst_categories_tipo_options
    r = OHash.new
    
    r["-1"] = "[Elegir]"
    r["P"]  = "Producto"
    r["S"]  = "Servicio"
    
    return r
  end
  
  
  def lst_categorias_productos_options
    r = OHash.new
    
    cats = Categoria.find_all_by_tipo "P", :order => "nombre"
    
    cats.each do |c|
      r[c.id.to_s] = c.nombre
    end
    
    return r
  end
  
  
  def lst_categorias_servicios_options
    r = OHash.new
    
    cats = Categoria.find_all_by_tipo "S", :order => "nombre"
    
    cats.each do |c|
      r[c.id.to_s] = c.nombre
    end
    
    return r
  end
  
  
  def metadata_ejecutivo
    r = OHash.new
    
    execs = User.list_of :executives
    
    execs.each do |e|
      r[e.id.to_s] = e.user_name
    end
    
    return r
  end
  
  
  def metadata_estado_proyecto
    r = OHash.new
    
    r["0"] = "En proceso"
    r["1"] = "Terminado"
    r["2"] = "Perdido"
    
    return r
  end
  
  
  def metadata_estado_diseno
    r = OHash.new
    
    r["-1"] = "[Ninguno]"
    
    [E_DISENO_EN_PROCESO, E_DISENO_SIN_ASIGNAR, E_DISENO_POR_APROBAR, E_DISENO_OBSERVADO, E_DISENO_APROBADO].each do |e|
      r[e.to_s] = ESTADOS[e][:label]
    end
    
    return r
  end
  
  
  def metadata_estado_planeamiento
    r = OHash.new
    
    r["-1"] = "[Ninguno]"
    
    [E_PLANEAMIENTO_SIN_ASIGNAR, E_PLANEAMIENTO_EN_PROCESO, E_PLANEAMIENTO_POR_APROBAR, E_PLANEAMIENTO_TERMINADO].each do |e|
      r[e.to_s] = ESTADOS[e][:label]
    end
    
    return r
  end
  
  
  def metadata_estado_costos
    r = OHash.new
    
    r["-1"] = "[Ninguno]"
    
    [E_COSTOS_EN_PROCESO, E_COSTOS_TERMINADO].each do |e|
      r[e.to_s] = ESTADOS[e][:label]
    end
    
    return r
  end
  
  
  def wo_client_options
    @orders = Orden.list_all
    
    r = OHash.new
    r["-1"] = "[Cliente]"
    
    @orders.each do |o|
      id   = o.proyecto.account.id.to_s
      name = o.proyecto.account.name
      
      if r[id].nil?
        r[id] = name
      end
    end
    
    return r
  end
  
  
  def wo_day_options
    r= OHash.new
    r["-1"] = "[D&iacute;a]"
    
    for i in 1..31 do
      r[i.to_s] = i.to_s
    end
    
    return r
  end
  
  
  def wo_month_options
    r= OHash.new
    r["-1"] = "[Mes]"
    
    for i in 1..12 do
      r[i.to_s] = Date::MONTHNAMES[i]
    end
    
    return r
  end
  
  
  def wo_year_options
    r= OHash.new
    r["-1"] = "[A&ntilde;o]"
    
    for i in 2006..(Time.now.year + 1) do
      r[i.to_s] = i.to_s
    end
    
    return r
  end
  
  
  def tc_admin_year_options
    r= OHash.new
    r["-1"] = "[A&ntilde;o]"
    
    for i in 2006..(Time.now.year + 1) do
      r[i.to_s] = i.to_s
    end
    
    return r
  end
  
  
  def wo_exec_options
    r= OHash.new
    
    r["-1"] = "[Ejecutivo]"
        
    execs = User.list_of :executives
    
    execs.each do |e|
      r[e.id] = e.user_name
    end
    
    return r
  end
  
  
  def validate_atributos(var, val)
    err = ""
    
    val.split("\n").each do |line|
      unless line =~ /^(txt|com|num|chk|sep|lin) (.+?)$/
        err = "Linea invalida: \"" + line + "\"<br>"
      end
    end
    
    return err
  end
  
  
  def solo_entrega_options
    r = OHash.new
    
    r["1"] = "S&oacute;lo entrega"
    r["0"] = "Instalaci&oacute;n"
    
    return r
  end
  
  
  def entrega_en_un_punto_options
    r = OHash.new
    
    r["1"] = "Entrega en un punto"
    r["0"] = "Entrega en varios puntos"
    
    return r
  end
  
  
  def alquiler_options
    r = OHash.new
    
    r["1"] = "Alquiler"
    r["0"] = "Venta"
    
    return r
  end
  
  
  def tipo_de_presentacion_options
    r = OHash.new
    
    r["-1"] = "[Elija un tipo]"
    TIPO_DE_PRESENTACION.each do |n, i|
      r[n] = i
    end
    
    return r
  end
  
  
  def validate_authorize_consorcio(var, val)
    puts '.'
    if val == Password.get("Autorizacion Consorcio", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def validate_void(var, val)
    if val == Password.get("Anulacion de ODT", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def validate_set_standby(var, val)
    if val == Password.get("ODT en Standby", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def validate_op_date_redef_op(var, val)
    if val == Password.get("Fecha de Entrega (Op)", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def validate_op_date_redef_exec(var, val)
    if val == Password.get("Fecha de Entrega (Ej)", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def validate_load_invoices_facturacion_password(var, val)
    if val == Password.get("Cargo Facturas - Facturacion", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def validate_load_invoices_cobranza_password(var, val)
    if val == Password.get("Cargo Facturas - Cobranza", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def facturada_options
    r = OHash.new
    r["-1"] = "[Todos]"
    r["1"]  = "Facturadas"
    r["0"]  = "No facturadas"
    
    return r
  end
  
  def estado_options
    r = OHash.new
    r["-1"]  = "[Todos]"
    r["100"] = "Terminado"
    r["101"] = "Perdido"
    r["102"] = "Anulado"
    
    return r
  end
  
  
  def status_options
    r = OHash.new
    r["-1"] = "[Todos]"
    
    [E_NUEVO, E_DISENO_EN_PROCESO, E_DISENO_SIN_ASIGNAR, E_DISENO_POR_APROBAR, E_DISENO_OBSERVADO, E_DISENO_APROBADO, E_PLANEAMIENTO_SIN_ASIGNAR, E_PLANEAMIENTO_POR_APROBAR, E_PLANEAMIENTO_EN_PROCESO, E_PLANEAMIENTO_OBSERVADO,E_PLANEAMIENTO_TERMINADO, E_COSTOS_EN_PROCESO, E_COSTOS_TERMINADO, E_OPERACIONES_EN_PROCESO, E_OPERACIONES_TERMINADO].each do |s|
      r[s.to_s] = ESTADOS[s][:label]
    end
    
    return r
  end
  
  
  def designer_options
    chic_people = User.list_of :designers
    
    r = OHash.new
    r["-1"] = "[Todos]"
    
    chic_people.each do |u|
      r[u.id] = u.full_name
    end
    
    return r
  end
  
  
  def executive_options
    execs = User.list_of :executives
    
    r = OHash.new
    r["-1"] = "[Todos]"
    
    execs.each do |u|
      r[u.id] = u.full_name
    end
    
    return r
  end
  
  
  def report_monthly_client_year_options
    r= OHash.new
    r["-1"] = "[A&ntilde;o]"
    
    for i in 2007..Time.now.year do
      r[i.to_s] = i.to_s
    end
    
    return r
  end
  
  
  def gr_type_options
    r = OHash.new
    
    [T_GARANTIA, T_RECLAMO].each do |t|
      r[t.to_s] = TIPO_PROYECTO[t]
    end
    
    return r
  end
  
  
  def io_type_options
    r = OHash.new
    
    [T_ORDEN_INTERNA, T_OTRO].each do |t|
      r[t.to_s] = TIPO_PROYECTO[t]
    end
    
    return r
  end
  
  
  def validate_change_et_password(var, val)
    if val == Password.get("Cambiar Empresa o Tipo", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def validate_grio_password(var, val)
    if val == Password.get("Crear Garantia/Reclamo", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def ventas_report_category_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    TIPO_DE_VENTA.each_with_index do |t, i|
      r[i.to_s] = t
    end
    
    return r
  end
  
  
  def ventas_report_project_type_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    TIPO_PROYECTO.each do |t|
      r[t[0].to_s] = t[1]
    end
    
    return r
  end
  
  
  def ventas_report_client_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    clients = Account.find_by_sql "SELECT DISTINCT accounts.id,
                                          accounts.name
                                     FROM accounts,
                                          proyectos
                                    WHERE proyectos.account_id=accounts.id
                                      AND accounts.deleted='0'
                                      AND proyectos.anulado='0'
                                      AND proyectos.con_orden_de_trabajo='1'
                                 ORDER BY accounts.name"
    
    clients.each do |c|
      r[c.id] = c.name
    end
    
    return r
  end
  
  
  def design_report_client_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    clients = Account.find_by_sql "SELECT DISTINCT accounts.id,
                                          accounts.name
                                     FROM accounts,
                                          proyectos
                                    WHERE proyectos.account_id=accounts.id
                                      AND accounts.deleted='0'
                                      AND proyectos.anulado='0'
                                 ORDER BY accounts.name"
    
    clients.each do |c|
      r[c.id] = c.name
    end
    
    return r
  end
  
  
  def estado_diseno_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    [E_DISENO_EN_PROCESO, E_DISENO_SIN_ASIGNAR, E_DISENO_POR_APROBAR, E_DISENO_OBSERVADO, E_DISENO_APROBADO].each do |e|
      r[e.to_s] = ESTADOS[e][:label]
    end
    
    return r
  end
  
  
  def sales_stage_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    clients = Account.find_by_sql "SELECT DISTINCT sales_stage
                                     FROM opportunities
                                    WHERE NOT #{SQL_VERA_DELETED}
                                 ORDER BY sales_stage"
    
    clients.each do |c|
      r[c.sales_stage] = c.sales_stage
    end
    
    return r
  end
  
  
  def role_options
    r = OHash.new
    
    roles = Rol.find :all, :order => "name"
    
    roles.each do |ro|
      r[ro.id.to_s] = ro.name
    end
    
    return r
  end
  
  
  def status_facturation_options
    r = OHash.new
    r["-1"] = "[Elegir]"
    
    STATUS_ENTREGA.each do |k, v|
      r[k] = v
    end
    
    return r
  end
  
  
  def status_factura_options
    r = OHash.new
    r["-1"] = "[Elegir]"
    
    STATUS_FACTURA.each do |k, v|
      r[k] = v
    end
    
    return r
  end
  
  
  def validate_void_factura_password(var, val)
    if val == Password.get("Anulacion de Factura", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def validate_blank_factura_password(var, val)
    if val == Password.get("Factura en Blanco", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def validate_void_nota_password(var, val)
    if val == Password.get("Anulacion de Nota de Credito", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def validate_delete_opportunity_password(var, val)
    if val == Password.get("Eliminar Oportunidad", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def validate_modificacion_monto(var, val)
    if val == Password.get("Modificacion de Monto", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def validate_void_guia_password(var, val)
    if val == Password.get("Anular Guia de Remision", @vars['empresa']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def factura_contraentrega_options
    r = OHash.new
    r["1"] = "Contraentrega"
    r["0"] = "D&iacute;as de Pago"
    return r
  end
  
  
  def factura_tipo_adelanto_options
    r = OHash.new
    r["P"] = "Porcentaje"
    r["M"] = "Monto"
    return r
  end
  
  def panel_misc_options
    r = OHash.new
    r["-1"] = "[Todos]"
    r["1"]  = "Si"
    r["0"]  = "No"
    return r
  end
  
  
  def panel_autorizado_para_facturar_options
    r = OHash.new
    r["-1"] = "[Todos]"
    r["0"]  = "No autorizado"
    r["1"]  = "Autorizado"
    return r
  end
  
  
  def panel_status_facturacion_options
    r = OHash.new
    r["-1"]              = "[Todos]"
    r[F_POR_FACTURAR]    = "Pendiente por Facturar"
    r[F_FACTURA_PARCIAL] = "Facturado parcial"
    r[F_FACTURA_TOTAL]   = "Facturado total"
    r[F_NO_FACTURABLE]   = "No Facturable"
    return r
  end
  
  
  def panel_status_cobranza_options
    r = OHash.new
    r["-1"]         = "[Todos]"
    r[C_POR_COBRAR] = "Pendiente por Cobrar"
    r[C_COBRADO]    = "Cobrado"
    return r
  end
  
  
  def anulado_options
    r = OHash.new
    r["-1"] = "[Todos]"
    r["1"]  = "Anulado"
    r["0"]  = "No anulado"
    return r
  end
  
  
  def flow_report_client_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    clients = Account.find_by_sql "
      SELECT DISTINCT accounts.id,
                       accounts.name
                  FROM accounts,
                       proyectos,
                       ordenes_facturas,
                       facturas
                 WHERE proyectos.account_id=accounts.id
                   AND ordenes_facturas.proyecto_id=proyectos.id
                   AND ordenes_facturas.factura_id=facturas.id
                   AND facturas.anulada='0'
                   AND facturas.en_blanco='0'
                   AND accounts.deleted='0'
              ORDER BY accounts.name"
    
    clients.each do |c|
      r[c.id] = c.name
    end
    
    return r
  end
  
  
  def new_guia_serie_options
    return NEW_GUIA_SERIES
  end
  
  
  def guia_medida_options
    r = OHash.new
    r["-1"]    = "[Elegir]"
    r["Und"]   = "Und"
    r["Pzs"]   = "Pzs"
    r["Ml"]    = "Ml"
    r["Juego"] = "Juego"
    
    return r
  end
  
  
  def validate_factura_cliente(var, val)
    a = Account.find_by_name val
    
    if a.nil?
      return "No se encontr&oacute; un Cliente en el CRM con ese nombre"
    else
      return ""
    end
  end
  
  
  def validate_ajax_account(var, val)
    a = Account.search val
    
    if a.nil?
      return "No se encontr&oacute; un Cliente en el CRM con ese nombre"
    else
      return ""
    end
  end
  
  
  def validate_interna_password(var, val)
    if val == Password.get("Crear Orden Interna", @vars['empresa_vendedora']['value'])
      return ""
    else
      return "Contrase&ntilde;a no v&aacute;lida"
    end
  end
  
  
  def empresa_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    EMPRESA_VENDEDORA.each_with_index do |n, i|
      r[i.to_s] = n
    end
    
    return r
  end
  
  
  def report_empresa_options
    r = OHash.new
    
    EMPRESA_VENDEDORA.each_with_index do |n, i|
      r[i.to_s] = n
    end
    
    return r
  end
  
  
  def ventas_empresa_options
    r = OHash.new
    
    EMPRESA_VENDEDORA.each_with_index do |n, i|
      r[i.to_s] = n
    end
    
    return r
  end
  
  
  def empresas_checkbox_options
    r = OHash.new
    
    EMPRESA_VENDEDORA.each_with_index do |n, i|
      r[i.to_s] = n
    end
    
    return r
  end
  
  
  def factura_estado_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    r["ANULADA"]    = "Anulada"
    r["EMITIDA"]    = "Emitida"
    r["EN_BLANCO"]  = "En Blanco"
    r["COBRADA"]    = "Cobrada"
    r["POR_COBRAR"] = "Por Cobrar"
    
    return r
  end
  
  
  def factura_estado_facturacion_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    r["1"]  = "Pendiente por Facturar"
    r["0"]  = "Facturado"
    
    return r
  end
  
  
  def validate_dias_plazo(var, val)
    return "Debes ingresar un n&uacute;mero v&aacute;lido" unless val =~ /^[0-9]+$/
    return "No debe exceder 90 d&iacute;as" if val.to_i > 90
    return ""
  end
  
  
  def guia_serie_options
    s = GuiaDeRemision.maximum('serie')
    
    r = OHash.new
    r["-1"] = "[Todos]"
    
    1.upto(s) do |i|
      r[i.to_s] = i.to_s.rjust(3, "0")
    end
    
    return r
  end
  
  
  def notifications_report_options
    r = OHash.new
    
    r["-1"] = "[Todos]"
    
    NOTIFICACIONES.each do |k, v|
      r[k] = v
    end
    
    return r
  end
  
  
  def panel_facturas_boletas_recepcion
    r = OHash.new
    r["-1"] = "[Todos]"
    r["0"]  = "Sin fecha de recepci&oacute;n"
    r["1"]  = "Con fecha de recepci&oacute;n"
    
    return r
  end
  
  
  def validate_fact_price_redef_exec(var, val)
    if val == Password.get("Cambio de Precio de ODT Facturada (Comercial)", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def validate_fact_price_redef_fact(var, val)
    if val == Password.get("Cambio de Precio de ODT Facturada (Facturacion)", @vars['empresa']['value'])
      ""
    else
      "C&oacute;digo de autorizaci&oacute;n incorrecto"
    end
  end
  
  
  def solicitado_por_options
    r = OHash.new
    r["-1"] = "[Elegir]"
    
    OP_DATE_REDEF_SOLICITADO_POR.each do |k, v|
      r[k] = v
    end
    
    return r
  end
  
  
  def con_fecha_de_entrega_options
    r       = OHash.new
    r["-1"] = "[Todos]"
    r["1"]  = "Si"
    r["0"]  = "No"
    return r
  end
  
  
  def se_necesita_supervisor_options
    r = OHash.new
    r["-1"] = "[Elegir]"
    r["0"]  = "No"
    r["1"]  = "Si"
    return r
  end
  
  
  def op_supervisor_options
    r = OHash.new
    r["-1"] = "[Elegir]"
    
    User.list_of(:op_supervisor).each do |u|
      r[u.id] = u.full_name
    end
    
    return r
  end
  
  
  def consumption_facturation_status_options
    r = OHash.new
    
    r[F_FACTURA_TOTAL]   = "Facturado Total"
    r[F_FACTURA_PARCIAL] = "Facturado Parcial"
    r[F_POR_FACTURAR]    = "Sin Factura"
    
    return r
  end
  
  
  def consumption_billing_status_options
    r = OHash.new
    
    r[C_POR_COBRAR] = "Por Cobrar"
    r[C_COBRADO]    = "Cobrado"
    
    return r
  end
  
  
  def tipo_proyecto_options
    r = OHash.new
    TIPO_PROYECTO.each do |k, v|
      r[k.to_s] = v
    end
    
    return r
  end
  
  
  def validate_percent(var, val)
    if val =~ /^[0-9]+$/
      if val.to_i >= 0 && val.to_i <= 100
        ""
      else
        "Debes ingresar un porcentaje v&aacute;lido"
      end
    else
      "Debes ingresar un porcentaje v&aacute;lido"
    end
  end
  
  
  def validate_orden_relacionada(var, val)
    p = Proyecto.find_by_sql "
      SELECT *
        FROM proyectos
       WHERE orden_id='#{val}'
         AND anulado='0'
      "
    
    if p.empty?
      return "N&uacute;mero de Orden inv&aacute;lida o inexistente"
    else
      return ""
    end
  end
end

