class Mail < ActiveRecord::Base
  
  def before_create
    self.from_name    ||= EMAIL_FROM_NAME
    self.from_address ||= EMAIL_FROM_ADDRESS
    self.is_html      ||= false
    self.sent         ||= false
  end
  
  
  def self.send_notification_mail
    @recipients.each do |u|
      m = Mail.new(
        :subject    => @subject,
        :to_address => u.email1,
        :body       => @body
      )
      m.save
    end
  end
  
  
  def self.log_notification(tipo)
    n = Notificacion.new({
      :user_id     => @user.id,
      :proyecto_id => @project.id,
      :tipo        => tipo,
      :descripcion => @body
    })
    n.save
  end
  
  
  def self.url_for(object)
    c = object.class
    
    if c == Proyecto
      project = object
      if project.con_orden_de_trabajo?
        return "http://#{INTERNAL_IP}:3000/orders/#{project.orden_id}"
      else
        return "http://#{INTERNAL_IP}:3000/projects/#{project.id}"
      end
    
    elsif c == FechasDeEntrega
      date = object
      return Mail.url_for(date.proyecto) + "/operations/#{date.id}"
    
    else
      raise "Mail: Unknown Object Class to give an URL for"
    end
  end
  
  
  def self.info_for(object)
    c = object.class
    
    if c == Proyecto
      project = object
      
      if project.con_orden_de_trabajo?
        type = 'Orden ' + project.orden_id.to_s
      else
        type = 'Proyecto ' + project.id.to_s
      end
      
      message = <<EOF
--------------------------------------------------------------------------------
#{project.nombre_proyecto}
#{type}
Cliente:   #{project.account.name}
Ejecutivo: #{project.executive.full_name}

#{Mail.url_for project}
--------------------------------------------------------------------------------

EOF
      
    elsif c == FechasDeEntrega
      date    = object
      message = <<EOF
Fecha:    #{date.fecha.long_format}
Cantidad: #{date.cantidad}
Detalle:
#{date.detalle}
Enlace:   #{Mail.url_for date}
EOF
    
    else
      raise "Mail: Unknown Object Class to give info for"
    end
    
    return message[0..-2] # Why's that? Because using a Heredoc keeps a
                          # newline at the end, which I don't want.
  end
  
  
  def self.message(project, from, to, message, aid)
    body = <<EOF
Area: #{AREAS[aid][:label]}
De:   #{from.full_name}

#{message}

#{Mail.info_for project}
EOF
    
    to.each do |u|
      m = Mail.new(
        :subject    => '[MNSJ] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => from.id,
      :tipo        => "MNSJ",
      :descripcion => body,
      :metadata    => aid
    })
    n.save
  end
  
  
  def self.assign_designer(uuid, pid, uid)
    project = Proyecto.find pid
    exec    = project.executive
    user    = User.find uid
    
    # First, to the designer himself
    m = Mail.new(
      :subject    => '[ASIGN] ' + project.nombre_proyecto,
      :to_address => user.email1
    )
    
    m.body = <<EOF
Te ha sido asignado este proyecto.

#{Mail.info_for project}
EOF
    m.save
    
    # Then, to the executive
    m = Mail.new(
      :subject    => '[ASIGN] ' + project.nombre_proyecto,
      :to_address => exec.email1
    )
    
    m.body = <<EOF
El Jefe de Diseño ha asignado este proyecto al diseñador #{user.full_name}.

#{Mail.info_for project}
EOF
    m.save
    
    n = Notificacion.new({
      :user_id     => uuid,
      :proyecto_id => pid,
      :tipo        => "ASIGN",
      :descripcion => m.body
    })
    n.save
  end
  
  
  def self.assign_planner(uuid, pid, uid)
    project = Proyecto.find pid
    user    = User.find uid
    
    m = Mail.new(
      :subject    => '[ASIGN] ' + project.nombre_proyecto,
      :to_address => user.email1
    )
    
    m.body = <<EOF
Te ha sido asignado este proyecto.

#{Mail.info_for project}
EOF
    m.save
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "ASIGN",
      :descripcion => m.body
    })
    n.save
  end
  
  
  def self.sent_to_area(uid, project, aid)
    exec = project.executive
    
    if (aid == A_DISENO)
      area = "Diseño"
      dest = User.list_of :chief_designers
    elsif (aid == A_COSTOS)
      area = "Costos"
      dest = User.list_of :costs
    elsif (aid == A_PLANEAMIENTO)
      area = "Planeamiento"
      dest = User.list_of :planners
    elsif (aid == :operations_mob)
      area = "Operaciones"
      dest = User.list_of :operations_mob
    elsif (aid == :operations_arq)
      area = "Operaciones"
      dest = User.list_of :operations_arq
    elsif (aid == A_INNOVACIONES)
      area = "Innovaciones"
      dest = User.list_of :innovations
    elsif (aid == A_INSTALACIONES)
      area = "Instalaciones"
      dest = User.list_of :installations
    end
    
    body = <<EOF
Enviado al área: #{area}

#{Mail.info_for project}
EOF
    
    dest.each do |d|
      m = Mail.new(
        :subject    => '[NUEVO] ' + project.nombre_proyecto,
        :to_address => d.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => project.id,
      :tipo        => "NUEVO",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.notification(uid, pid, aid)
    project = Proyecto.find pid
    exec    = project.executive
    
    if (aid == A_DISENO)
      area   = "Diseño"
      sender = User.find(project.area.encargado_diseno).full_name
    elsif (aid == A_COSTOS)
      area = "Costos"
      sender = User.list_of(:costs)[0].full_name
    else
      area = "Planeamiento"
      sender = User.list_of(:chief_plannings)[0].full_name
    end
    
    m = Mail.new(
      :subject    => '[NOTIF] ' + sender + ": " + project.nombre_proyecto,
      :to_address => exec.email1
    )
    
    m.body = <<EOF
Notificación de #{sender} sobre #{area}.

#{Mail.info_for project}
EOF
    
    m.save
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "NOTIF",
      :descripcion => m.body,
      :metadata    => aid
    })
    n.save
  end
  
  
  def self.notification_of_observed(uid, pid, aid)
    project = Proyecto.find pid
    exec    = project.executive
    
    # We are going to send two messages, one to the Designer whose
    # design has been observed and one to the Chief Designer(s)
    
    body = <<EOF
Marcado como observado por el Ejecutivo.

#{Mail.info_for project}
EOF
    
    # First, the Designer
    m = Mail.new(
      :subject    => "[OBSV] " + exec.full_name + ": " + project.nombre_proyecto,
      :body       => body,
      :to_address => User.find(project.area.encargado_diseno).email1
    )
    m.save
    
    # That's nice. Now, to the Chief Designer(s)
    chiefs = User.list_of :chief_designers
    
    chiefs.each do |c|
      m = Mail.new(
        :subject    => "[OBSV] " + exec.full_name + ": " + project.nombre_proyecto,
        :body       => body,
        :to_address => c.email1
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "OBSV",
      :descripcion => body,
      :metadata    => aid
    })
    n.save
  end
  
  
  def self.notification_of_design_to_devel(uid, project)
    users  = User.list_of(:development)
    
    body = <<EOF
El diseño ha sido enviado a Desarrollo para revisión.

#{Mail.info_for project}
EOF
    
    users.each do |u|
      m = Mail.new(
        :subject    => "[DIDE] " + project.nombre_proyecto,
        :body       => body,
        :to_address => u.email1
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => project.id,
      :tipo        => "DIDE",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.notification_of_design_approved(uid, pid)
    project = Proyecto.find pid
    exec    = project.executive
    
    users  = [User.find(project.area.encargado_diseno), exec] + User.list_of(:chief_designers)
    
    body = <<EOF
El diseño ha sido aprobado por el Ejecutivo.

#{Mail.info_for project}
EOF
    
    users.each do |u|
      m = Mail.new(
        :subject    => "[DIAP] " + project.nombre_proyecto,
        :body       => body,
        :to_address => u.email1
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "DIAP",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.urgent_notification(uid, pid, area)
    project    = Proyecto.find pid
    
    if area == A_DISENO
      recipients = User.notification_list_of("urgent_design")
    elsif area == A_PLANEAMIENTO
      recipients = User.notification_list_of("urgent_planning")
    elsif area == A_COSTOS
      recipients = User.notification_list_of("urgent_costs")
    end
    
    body = <<EOF
Marcado como Urgente.

#{Mail.info_for project}
EOF
    
    recipients.each do |r|
      m = Mail.new(
        :subject    => '[URGT] ' + project.nombre_proyecto,
        :to_address => r.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "URGT",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.cotizacion(exec, dest, codigo, body)
    m = Mail.new(
      :subject      => 'Cotizacion ' + codigo,
      :from_name    => exec.full_name,
      :from_address => exec.email1,
      :to_address   => dest,
      :is_html      => true,
      :body         => body
    )
    m.save
  end
  
  
  def self.void_notification(uid, pid)
    project = Proyecto.find pid
    body    = <<EOF
Anulado por el siguiente motivo:

#{project.motivo_anulacion}

#{Mail.info_for project}
EOF
    
    users = User.notification_list_of("void_odt")
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[ANULA] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "ANULA",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.internal_order_notification(uid, pid)
    project = Proyecto.find pid
    body = <<EOF
Marcado como Orden Interna.

#{Mail.info_for project}
EOF
    
    users = User.notification_list_of("internal_odt")
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[INTER] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "INTER",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.order_amount_change_notification(uid, pid, motive, old_price, new_price)
    project = Proyecto.find pid
    body    = <<EOF
El monto de venta ha cambiado.

Anterior: #{old_price}
Nuevo:    #{new_price}

Motivo:
#{motive}

#{Mail.info_for project}
EOF
    
    users = User.notification_list_of("odt_amount_change")
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[ODTCM] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "ODTCM",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.order_amount_change_notification_with_last_guia(uid, pid, motive, old_price, new_price)
    project = Proyecto.find pid
    body    = <<EOF
El monto de venta ha cambiado posterior a la firma de la Guía final.

Anterior: #{old_price}
Nuevo:    #{new_price}

Motivo:
#{motive}

#{Mail.info_for project}
EOF
    
    users = User.notification_list_of("odt_amount_change")
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[ODTCG] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "ODTCG",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.product_qty_change_notification(uid, pid)
    project = Proyecto.find pid
    
    body = <<EOF
Ha cambiado la cantidad de productos.

#{Mail.info_for project}
EOF
    
    users = User.notification_list_of("product_qty_change")
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[CANTPR] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "CANTPR",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.odt_invoice(uid, pid)
    project = Proyecto.find pid
    body    = <<EOF
Ha sido autorizado para Facturar.

#{Mail.info_for project}
EOF
    
    users = User.notification_list_of("odt_invoice")
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[OFACT] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => pid,
      :tipo        => "OFACT",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.fecha_de_entrega_body(date, action, whom)
    if whom == :op
      w = "OPERACIONES"
    elsif whom == :exec
      w = "el EJECUTIVO"
    else
      raise "Mail: To whom, you say?"
    end
    
    body    = <<EOF
La Fecha de Entrega Parcial ha sido #{action} por #{w}.

#{Mail.info_for date}

#{Mail.info_for date.proyecto}
EOF
    
    return body
  end
  
  
  def self.set_operations_data_for_subtipo
    if @project.subtipo_nuevo_proyecto_mobiliario?
      @operations = :operations_mob
      @list       = "op_date_confirm_mob"
    else
      @operations = :operations_arq
      @list       = "op_date_confirm_arq"
    end
  end
  
  
  def self.fecha_entrega_accepted_by_op(user, date)
    @project    = date.proyecto
    @user       = user
    Mail.set_operations_data_for_subtipo
    @recipients = ([@project.executive] + User.notification_list_of(@list)).uniq
    @subject    = '[FENTR][OK] ' + @project.nombre_proyecto
    @body       = Mail.fecha_de_entrega_body(date, "ACEPTADA", :op)
    
    Mail.send_notification_mail
    Mail.log_notification "FENTROKOP"
  end
  
  
  def self.fecha_entrega_accepted_by_exec(user, date)
    @project    = date.proyecto
    @user       = user
    Mail.set_operations_data_for_subtipo
    @recipients = (User.list_of(@operations) + User.notification_list_of(@list)).uniq
    @subject    = '[FENTR][OK] ' + @project.nombre_proyecto
    @body       = Mail.fecha_de_entrega_body(date, "ACEPTADA", :exec)
    
    Mail.send_notification_mail
    Mail.log_notification "FENTROKEXEC"
  end
  
  
  def self.fecha_entrega_redefined_by_exec(user, date)
    @project    = date.proyecto
    @user       = user
    Mail.set_operations_data_for_subtipo
    @recipients = (User.list_of(@operations) + User.notification_list_of(@list)).uniq
    @subject    = '[FENTR][RE] ' + @project.nombre_proyecto
    @body       = Mail.fecha_de_entrega_body(date, "REPLANTEADA", :exec)
    
    Mail.send_notification_mail
    Mail.log_notification "FENTRREEXEC"
  end
  
  
  def self.fecha_entrega_redefined_by_op(user, date)
    @project    = date.proyecto
    @user       = user
    Mail.set_operations_data_for_subtipo
    @recipients = ([@project.executive] + User.notification_list_of(@list)).uniq
    @subject    = '[FENTR][RE] ' + @project.nombre_proyecto
    @body       = Mail.fecha_de_entrega_body(date, "REPLANTEADA", :op)
    
    Mail.send_notification_mail
    Mail.log_notification "FENTRREOP"
  end
  
  
  def self.fecha_entrega_modified(user, date)
    @project    = date.proyecto
    @user       = user
    Mail.set_operations_data_for_subtipo
    @recipients = ([@project.executive] + User.list_of(@operations) + User.notification_list_of(@list)).uniq
    @subject    = '[FENTR][MO] ' + @project.nombre_proyecto
    
    if date.mod_propuesto_por_area == "C"
      area = "COMERCIAL"
    elsif date.mod_propuesto_por_area == "O"
      area = "OPERACIONES"
    else
      area = "?"
    end
    
    @body = <<EOF
Por solicitud del Area #{area} la Fecha de Entrega ha sido modificada
con claves de autorización.

Fecha Original: #{date.fecha_original.long_format}
Nueva Fecha:    #{date.fecha.long_format}
Motivo:
#{date.mod_motivo}

#{Mail.info_for date}

#{Mail.info_for @project}
EOF
    
    Mail.send_notification_mail
    Mail.log_notification "FENTRMO"
  end
  
  
  def self.fecha_entrega_awaiting_auth(user, date, waiting_for)
    @project    = date.proyecto
    @user       = user
    Mail.set_operations_data_for_subtipo
    @recipients = User.notification_list_of(@list)
    @subject    = '[FENTR][MA] ' + @project.nombre_proyecto
    
    if waiting_for == :ex
      @recipients << @project.executive
      tal_patin = "el Ejecutivo"
    else
      @recipients = @recipients + User.list_of(@operations)
      tal_patin = "Operaciones"
    end
    
    @body    = <<EOF
La Fecha de Entrega está en proceso de modificación, con espera de
autorización de #{tal_patin}.

#{Mail.info_for date}

#{Mail.info_for @project}
EOF
    
    Mail.send_notification_mail
    Mail.log_notification "FENTRMA"
  end
  
  
  def self.operaciones_denied(user, project, motive)
    @project    = project
    @user       = user
    @recipients = [@project.executive]
    @subject    = '[OPRE] ' + @project.nombre_proyecto
    
    @body = <<EOF
El envío de este Proyecto al área de Operaciones ha sido rechazado
por Operaciones.

Motivo:
#{motive}

#{Mail.info_for @project}
EOF
    
    Mail.send_notification_mail
    Mail.log_notification "OPDENY"
  end
  
  
  def self.facturated_price_redef_pending(uid, project, redef)
    moneda  = (project.moneda_odt == "S" ? "S/." : "$")
    
    body    = <<EOF
El precio de la ODT #{project.orden_id} parcialmente facturada ha sido
modificada y está esperando aprobación de Facturación.

Haga click en la siguiente dirección:
#{Mail.url_for project}/redefine_facturated_price

Monto original: #{moneda} #{redef.old_monto}
Nuevo monto:    #{moneda} #{redef.new_monto}

#{Mail.info_for project}
EOF
    
    users = User.notification_list_of("redefine_facturated_price")
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[ODTFP][RE] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => project.id,
      :tipo        => "ODTFPRE",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.facturated_price_redef_finished(uid, project, redef)
    moneda  = (project.moneda_odt == "S" ? "S/." : "$")
    
    body    = <<EOF
La modificación del precio de la ODT #{project.orden_id} parcialmente
facturada ha sido aprobada por Facturación.

Monto original: #{moneda} #{redef.old_monto}
Nuevo monto:    #{moneda} #{redef.new_monto}

#{Mail.info_for project}
EOF
    
    users = ([project.executive] + User.notification_list_of("redefine_facturated_price")).uniq
    
    users.each do |u|
      m = Mail.new(
        :subject    => '[ODTFP][OK] ' + project.nombre_proyecto,
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => project.id,
      :tipo        => "ODTFPOK",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.notify_insumos_percent_exceeded(p, percent)
    body    = <<EOF
Los insumos de la Orden #{p.orden_id} suman #{percent}% del monto
de venta.

http://#{INTERNAL_IP}:3000/orders/#{p.orden_id}/variable_cost
EOF
    
    users = User.notification_list_of("insumos_percent")
    
    users.each do |u|
      m = Mail.new(
        :subject    => "ODT #{p.orden_id} - Alerta suma de Insumos",
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    # Since this is done by cron, the user who generates this notification
    # will be jpuppo
    u = User.find_by_user_name "jpuppo"
    
    n = Notificacion.new({
      :user_id     => u.id,
      :proyecto_id => p.id,
      :tipo        => "INSUMO",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.notify_executive_commission(commission)
    body    = <<EOF
El Ejecutivo #{commission.user.full_name} ha generado una comisión
de $#{commission.monto} a cobrarse el #{commission.fecha_cobrada.strftime("%m/%Y")}.
EOF
    
    users = ([commission.user] + User.notification_list_of("commercial_manager")).uniq
    
    users.each do |u|
      m = Mail.new(
        :subject    => "Comisión de #{commission.user.full_name} (#{commission.fecha_cobrada.strftime("%m/%Y")})",
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
  end
  
  
  def self.odt_standby(uid, p)
    if p.en_standby?
      status = "está ahora en Standby"
      suffix = "A"
    else
      status = "ya no está en Standby"
      suffix = "B"
    end
    
    body    = <<EOF
La Orden #{p.orden_id} #{status}.
EOF
    
    users = User.notification_list_of("odt_in_standby")
    
    users.each do |u|
      m = Mail.new(
        :subject    => "[OST#{suffix}] #{p.nombre_proyecto}",
        :to_address => u.email1,
        :body       => body
      )
      m.save
    end
    
    n = Notificacion.new({
      :user_id     => uid,
      :proyecto_id => p.id,
      :tipo        => "ODTSBT#{suffix}",
      :descripcion => body
    })
    n.save
  end
  
  
  def self.operations_validator_disapproved(user, project, motive)
    @project    = project
    @user       = user
    @recipients = [@project.executive]
    @subject    = '[OPVD] ' + @project.nombre_proyecto
    
    @body = <<EOF
El envío de este Proyecto al área de Operaciones ha sido desaprobado
por el Validador.

Motivo:
#{motive}

#{Mail.info_for @project}
EOF
    
    Mail.send_notification_mail
    Mail.log_notification "OPVD"
  end
  
  
  def self.fecha_entrega_data_modified_by_executive(user, project)
    @project    = project
    @user       = user
    @recipients = User.notification_list_of(:op_date_data_modified)
    @subject    = '[FENTR][MO] ' + @project.nombre_proyecto
    @body       = "Los datos de las Fechas de Entrega han sido modificados por el Ejecutivo.

------------------------------------------------------------------------
"
    
    project.fechas_de_entrega.each do |fe|
      @body += "FECHA:    #{fe.fecha.long_format}
CANTIDAD: #{fe.cantidad}
DETALLE:

#{fe.detalle}

------------------------------------------------------------------------
"
    end
    
    Mail.send_notification_mail
    Mail.log_notification "FENTRMO"
  end
  
  
  
  
  def self.send_queued
    if File.exists? MAIL_LOCK_FILE
      return true
    end
    
    FileUtils.touch MAIL_LOCK_FILE
    
    mails = Mail.find_all_by_sent "0", :order => "created_on"
    
    mails.each do |m|
      begin
        unless m.to_address.nil? || m.to_address == "" || m.to_address == 'j@jgwong.org'
          Mailer.deliver_misc m.from_name + " <" + m.from_address + ">", m.to_address, m.subject, m.body, m.is_html?
        end
        
        m.sent = true
        m.save
      rescue
        # Duh!
      end
    end
    
    File.delete MAIL_LOCK_FILE
  end
  
  
  def self.check_lock_file
    sleep(10)
    
    if (File.exists? MAIL_LOCK_FILE) && (File.new(MAIL_LOCK_FILE).ctime < 15.minutes.from_now) && !(`ps aux` =~ /send_queued/)
      File.delete MAIL_LOCK_FILE
    end
  end
  
end
