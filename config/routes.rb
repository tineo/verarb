ActionController::Routing::Routes.draw do |map|
#  map.connect ":controller/service.wsdl", :action => "wsdl"
  map.connect "", :controller => "users", :action => "login"
  map.connect "import_orders", :controller => "projects", :action => "import_orders"
  map.connect "user/change_role", :controller => "users", :action => "change_role"
  map.connect "quicksearch", :controller => "projects", :action => "quicksearch"
  
  # TEMP
  map.connect "extras/remove", :controller => "projects", :action => "remove_op"
  map.connect "extras/mark", :controller => "projects", :action => "unmark_odt_for_export"
  map.connect "extras/rep", :controller => "projects", :action => "rep"
  map.connect "extras/do_the_tc_dance", :controller => "projects", :action => "do_the_tc_dance"
  map.connect "extras/cook", :controller => "exports", :action => "cook"
  
  map.connect "t", :controller => "projects", :action => "t"
  
  # We *love* beautiful URLs
  
  # Core
  map.connect "panel/", :controller => "projects", :action => "panel"
  map.connect "projects/", :controller => "projects", :action => "projects"
  map.connect "orders/", :controller => "projects", :action => "orders"
  map.connect "projects/sort/:field", :controller => "projects", :action => "set_sort_field", :tab => "projects"
  map.connect "orders/sort/:field", :controller => "projects", :action => "set_sort_field", :tab => "orders"
  map.connect "projects/page/:page", :controller => "projects", :action => "set_panel_page", :tab => "projects"
  map.connect "orders/page/:page", :controller => "projects", :action => "set_panel_page", :tab => "orders"
  
  # Misc
  map.connect "logout", :controller => "users", :action => "logout"
  map.connect "dashboard/", :controller => "dashboard", :action => "index"
  map.connect "export/budget/", :controller => "exports", :action => "export_for_budget"
  map.connect "export/orders/", :controller => "projects", :action => "export_orders"
  map.connect "export/guias/", :controller => "exports", :action => "export_guias"
  map.connect "import_accounts", :controller => "projects", :action => "import_accounts"
  map.connect "import_execs", :controller => "projects", :action => "import_execs"
  map.connect "reports/executives_quotas_cron", :controller => "exports", :action => "executives_quotas_cron"
  map.connect "export/insumos_cron", :controller => "exports", :action => "insumos_cron"
  map.connect "export/costo_variable_cron", :controller => "exports", :action => "costo_variable_cron"
  
  # Reports
  map.connect "reports", :controller => "reports", :action => "index"
  map.connect "reports/ventas", :controller => "reports", :action => "ventas"
  map.connect "reports/ventas/sort/:field", :controller => "reports", :action => "set_sort_field_ventas"
  map.connect "reports/executives_quotas", :controller => "reports", :action => "executives_quotas"
  map.connect "reports/executives_comissions/:year/:month/:uid", :controller => "reports", :action => "executives_comissions"
  map.connect "reports/monthly", :controller => "reports", :action => "monthly"
  map.connect "reports/monthly_data_accumulated", :controller => "reports", :action => "monthly_data_accumulated"
  map.connect "reports/monthly_data_by_month", :controller => "reports", :action => "monthly_data_by_month"
  map.connect "reports/monthly_data_by_year", :controller => "reports", :action => "monthly_data_by_year"
  map.connect "reports/account_movement", :controller => "reports", :action => "account_movement"
  map.connect "reports/commercial_briefing", :controller => "reports", :action => "commercial_briefing"
  map.connect "reports/design", :controller => "reports", :action => "design"
  map.connect "reports/facturation_flow", :controller => "reports", :action => "facturation_flow"
  map.connect "reports/facturation_flow_details", :controller => "reports", :action => "facturation_flow_details"
  map.connect "reports/billing_weekly_flow", :controller => "reports", :action => "billing_weekly_flow"
  map.connect "reports/notifications", :controller => "reports", :action => "notifications"
  map.connect "reports/odt_guias", :controller => "reports", :action => "odt_guias"
  map.connect "reports/facturation_pending", :controller => "reports", :action => "facturation_pending"
  map.connect "reports/facturation_pending/:uid", :controller => "reports", :action => "facturation_pending"
  # Reporte Truput
  map.connect "reports/truput_estimado_mes", :controller => "reports", :action => "truput_estimado_mes"
  map.connect "reports/truput_estimado_mes_detalle", :controller => "reports", :action => "truput_estimado_mes_detalle"
  # Reporte Estimado de Cierre de Venta
  map.connect "reports/estimado_cierre_de_venta", :controller => "reports", :action => "estimado_cierre_de_venta"
  map.connect "reports/estimado_cierre_de_venta_detalle", :controller => "reports", :action => "estimado_cierre_de_venta_detalle"
  map.connect "reports/odt_consumption", :controller => "reports", :action => "odt_consumption"
  map.connect "reports/costos_por_odt", :controller => "reports", :action => "costos_por_odt"
  map.connect "reports/resumen_truput_mensual", :controller => "reports", :action => "resumen_truput_mensual"
  map.connect "reports/odts_sin_fecha_cierre", :controller => "reports", :action => "odts_sin_fecha_cierre"
  map.connect "reports/otras_variables", :controller => "reports", :action => "otras_variables"
  map.connect "reports/t", :controller => "reports", :action => "t"
  map.connect "reports/t2", :controller => "reports", :action => "t2"
  
  # Admin
  map.connect "admin/", :controller => "admin", :action => "index"
  map.connect "admin/list/", :controller => "admin", :action => "list_admin"
  map.connect "admin/list/:lid", :controller => "admin", :action => "list_admin"
  map.connect "admin/executive_quotas", :controller => "users", :action => "admin_quotas"
  map.connect "admin/executive_quotas/edit", :controller => "users", :action => "admin_quotas_entry"
  map.connect "admin/ticker", :controller => "admin", :action => "ticker"
  map.connect "admin/passwords", :controller => "admin", :action => "passwords"
  map.connect "admin/import_sispre", :controller => "admin", :action => "import_sispre"
  map.connect "admin/insumos_percent", :controller => "admin", :action => "insumos_percent"
  map.connect "admin/update_variable_costs_cache", :controller => "admin", :action => "update_variable_costs_cache"
  
  # Roles
  map.connect "admin/roles", :controller => "roles", :action => "index"
  map.connect "admin/roles/list", :controller => "roles", :action => "list"
  map.connect "admin/roles/new", :controller => "roles", :action => "new"
  map.connect "admin/roles/edit/:id", :controller => "roles", :action => "edit"
  map.connect "admin/roles/delete/:id", :controller => "roles", :action => "delete"
  map.connect "admin/roles/users", :controller => "roles", :action => "user_list"
  map.connect "admin/roles/users/:id", :controller => "roles", :action => "user_edit"
    
  # Common stuff
  # We do things this way because we want to be able to call to the same
  # "object" as a Project or as an Order on the URL. Nice to know the users
  # hack URLs to work faster.
  
  # Common for Projects and Orders
  map.connect "/extras/auto_complete", :controller => "projects", :action => "auto_complete_for_account_name"
  
  ["projects", "orders"].each do |t|
    if t == "projects"
      type = "p"
    else
      type = "o"
    end
    
    map.connect "#{t}/:id", :controller => "projects", :action => "show", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/client/edit", :controller => "projects", :action => "edit_account", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/details", :controller => "projects", :action => "show_details", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/details/edit", :controller => "projects", :action => "edit_details", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/details/:did", :controller => "projects", :action => "show_detail", :type => type, :requirements => { :id => /\d+/, :did => /\d+/ }
    map.connect "#{t}/:id/details/:did/delete", :controller => "projects", :action => "delete_detail", :type => type, :requirements => { :id => /\d+/, :did => /\d+/ }
    map.connect "#{t}/:id/details/:did/edit", :controller => "projects", :action => "edit_detail", :type => type, :requirements => { :id => /\d+/, :did => /\d+/ }
    map.connect "#{t}/:id/details/:did/files/:fid", :controller => "projects", :action => "get_file", :type => type, :requirements => { :id => /\d+/, :did => /\d+/ }
    map.connect "#{t}/:id/details/:did/files/:fid/delete", :controller => "projects", :action => "delete_project_file", :type => type, :requirements => { :id => /\d+/, :did => /\d+/ }
    map.connect "#{t}/:id/details/:did/files/print/:fid", :controller => "projects", :action => "get_file", :type => type, :requirements => { :id => /\d+/, :did => /\d+/, :print => 1 }
    map.connect "#{t}/:id/details/new/product", :controller => "projects", :action => "add_product", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/details/new/service", :controller => "projects", :action => "add_service", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/areas", :controller => "projects", :action => "areas", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/edit", :controller => "projects", :action => "edit_project", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/edit_meta", :controller => "projects", :action => "edit_metadata", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/areas/send", :controller => "projects", :action => "send_to", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/design", :controller => "projects", :action => "design", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/design_development", :controller => "projects", :action => "design_development", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/planning", :controller => "projects", :action => "planning", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/costs", :controller => "projects", :action => "costs", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/post_message/:aid", :controller => "projects", :action => "post_message", :type => type, :requirements => { :id => /\d+/, :aid => /\d+/ }
    map.connect "#{t}/:id/costs/files/:fid", :controller => "projects", :action => "get_costs_file", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/costs/files/:fid/delete", :controller => "projects", :action => "delete_costs_doc", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/innovations", :controller => "projects", :action => "innovations", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/post_message/:aid", :controller => "projects", :action => "post_message", :type => type, :requirements => { :id => /\d+/, :aid => /\d+/ }
    map.connect "#{t}/:id/innovations/files/:fid", :controller => "projects", :action => "get_innovations_file", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/installations/files/:fid", :controller => "projects", :action => "get_installations_file", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/costs_docs_popup", :controller => "projects", :action => "costs_docs_popup", :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/details/files/:fid/toggle", :controller => "projects", :action => "toggle_attached_file", :type => type, :requirements => { :id => /\d+/, :did => /\d+/ }
    map.connect "#{t}/:id/installations", :controller => "projects", :action => "installations", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/assign_designer", :controller => "projects", :action => "assign_designer", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/assign_planner", :controller => "projects", :action => "assign_planner", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/notify_plan", :controller => "projects", :action => "notify_plan", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/notify_design", :controller => "projects", :action => "notify_design", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/notify_design_development", :controller => "projects", :action => "notify_design_development", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/notify_costs", :controller => "projects", :action => "notify_costs", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/operations", :controller => "projects", :action => "op_date", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/operations/:fid", :controller => "projects", :action => "op_date_item", :type => type, :requirements => { :id => /\d+/, :fid => /\d+/ }
    map.connect "#{t}/:id/operations/:fid/modify", :controller => "projects", :action => "op_date_modify", :type => type, :requirements => { :id => /\d+/, :fid => /\d+/ }
    map.connect "#{t}/:id/history_of_dates", :controller => "projects", :action => "history_of_dates", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/delete_opportunity", :controller => "projects", :action => "delete_opportunity", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/change_empresa_or_type", :controller => "projects", :action => "change_empresa_or_type", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/notifications", :controller => "projects", :action => "notifications", :type => type, :requirements => { :id => /\d+/ }
    map.connect "#{t}/:id/confirm", :controller => "projects", :action => "confirmation_data_of_order", :type => type, :requirements => { :id => /\d+/ }
  end
  
  
  # Projects and only projects stuff
  map.connect "projects/archive", :controller => "projects", :action => "archive"
  map.connect "projects/new/:id", :controller => "projects", :action => "new"
  map.connect "projects/:id/show", :controller => "projects", :action => "show", :requirements => { :id => /\d+/ }
  map.connect "projects/:id/cotizaciones", :controller => "projects", :action => "cotization", :requirements => { :id => /\d+/ }
  map.connect "projects/:id/cotizaciones/:cid", :controller => "projects", :action => "cotization", :requirements => { :id => /\d+/, :cid => /\d+/ }
  map.connect "projects/:id/cotizaciones/:cid/print", :controller => "projects", :action => "view_cotizacion", :requirements => { :id => /\d+/, :cid => /\d+/ }
  map.connect "projects/:id/cotizaciones/:cid/save/:filename", :controller => "projects", :action => "view_cotizacion", :save => "1", :requirements => { :id => /\d+/, :cid => /\d+/ }
  map.connect "projects/:id/cotizaciones/:cid/mark", :controller => "projects", :action => "mark_cotization", :requirements => { :id => /\d+/, :cid => /\d+/ }
  map.connect "projects/:id/cotizaciones/:cid/mail", :controller => "projects", :action => "email_cotizacion", :requirements => { :id => /\d+/, :cid => /\d+/ }
  map.connect "projects/:id/cotizaciones/:cid/mail/sent", :controller => "projects", :action => "cotizacion_sent", :requirements => { :id => /\d+/, :cid => /\d+/ }
  map.connect "projects/:id/preedit", :controller => "projects", :action => "promote", :pre_editing => "1", :requirements => { :id => /\d+/ }
  map.connect "projects/:id/promote", :controller => "projects", :action => "promote", :requirements => { :id => /\d+/ }
  map.connect "projects/new/:id/empty_ruc", :controller => "projects", :action => "empty_ruc"
  map.connect "projects/:id/confirmation_docs", :controller => "projects", :action => "confirmation_docs_popup", :requirements => { :id => /\d+/ }
  map.connect "projects/:id/confirmation_docs/:fid", :controller => "projects", :action => "get_confirmation_doc", :requirements => { :id => /\d+/ }
  map.connect "projects/:id/confirmation_docs/:fid/delete", :controller => "projects", :action => "delete_confirmation_doc", :requirements => { :id => /\d+/ }
  #map.connect "projects/:id/costs_docs_popup", :controller => "projects", :action => "costs_docs_popup", :requirements => { :id => /\d+/ }

  map.connect "projects/:id/account_blocked", :controller => "projects", :action => "account_blocked", :requirements => { :id => /\d+/ }
  map.connect "projects/:id/edit_fechas_de_entrega", :controller => "projects", :action => "edit_fechas_de_entrega", :requirements => { :id => /\d+/ }
  
  
  # Orders and only Orders stuff
  map.connect "orders/archive", :controller => "projects", :action => "archive_orders"
  map.connect "orders/:id/print", :controller => "projects", :action => "print_order", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/invoice", :controller => "projects", :action => "invoice", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/void", :controller => "projects", :action => "void_order", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/mark_post_venta", :controller => "projects", :action => "mark_post_venta", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/toggle_urgency", :controller => "projects", :action => "toggle_urgency", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/create_gr", :controller => "projects", :action => "create_gr", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/redefine_facturated_price", :controller => "projects", :action => "redefine_facturated_price", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/variable_cost", :controller => "projects", :action => "variable_cost", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/set_standby", :controller => "projects", :action => "set_standby", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/production", :controller => "projects", :action => "production", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/production/:fid", :controller => "projects", :action => "production_edit", :requirements => { :id => /\d+/, :fid => /\d+/ }
  
  # Orders Validation
  map.connect "orders/validation_list", :controller => "projects", :action => "validate_orders"
  
  # Opportunities
  map.connect "opportunities", :controller => "opportunities", :action => "panel"
  map.connect "opportunities/:id", :controller => "opportunities", :action => "show"
  map.connect "opportunities/accounts/auto_complete", :controller => "opportunities", :action => "auto_complete_for_account_name"
  map.connect "opportunities/sort/:field", :controller => "opportunities", :action => "set_sort_field"
  
  # Facturacion thingies
  map.connect "facturas", :controller => "facturation", :action => "facturas"
  map.connect "boletas", :controller => "facturation", :action => "boletas"
  map.connect "guias", :controller => "facturation", :action => "guias"
  map.connect "facturas/page/:page", :controller => "facturation", :action => "set_facturas_page", :tab => "facturas"
  map.connect "boletas/page/:page", :controller => "facturation", :action => "set_facturas_page", :tab => "boletas"
  
  # Facturas
  map.connect "facturas/:fid", :controller => "facturation", :action => "show_factura", :type => "f", :from => "f", :requirements => { :fid => /\d+/ }
  map.connect "cobranza/facturas/:fid", :controller => "facturation", :action => "show_factura", :type => "f", :from => "c", :requirements => { :fid => /\d+/ }
  map.connect "facturas/new", :controller => "facturation", :action => "new_factura_1", :type => "f"
  map.connect "facturas/:fid/add_order", :controller => "facturation", :action => "new_factura_1", :type => "f"
  map.connect "orders/:id/facturas/new", :controller => "facturation", :action => "new_factura_2", :type => "f", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/facturas/new/:fid", :controller => "facturation", :action => "new_factura_3", :type => "f", :requirements => { :id => /\d+/, :fid => /\d+/ }
  map.connect "facturas/:fid/edit", :controller => "facturation", :action => "edit_factura", :type => "f", :requirements => { :fid => /\d+/ }
  map.connect "facturas/:fid/print", :controller => "facturation", :action => "print_factura", :requirements => { :fid => /\d+/ }
  map.connect "facturas/:fid/print_preview", :controller => "facturation", :action => "print_factura_preview", :requirements => { :fid => /\d+/ }
  map.connect "facturas/:fid/notas/new", :controller => "notes", :action => "new_note_1", :type => "f", :requirements => { :fid => /\d+/ }
  map.connect "facturas/:fid/notas/new/:nid", :controller => "notes", :action => "new_note_2", :type => "f", :requirements => { :fid => /\d+/, :nid => /\d+/ }
  
  # Notas de Cr�dito
  map.connect "notas/:nid", :controller => "notes", :action => "show", :requirements => { :nid => /\d+/ }
  map.connect "notas/:nid/edit", :controller => "notes", :action => "edit", :requirements => { :nid => /\d+/ }
  map.connect "notas/:nid/blank", :controller => "notes", :action => "blank", :requirements => { :nid => /\d+/ }
  map.connect "notas/:nid/void", :controller => "notes", :action => "void", :requirements => { :nid => /\d+/ }

  
  # Boletas
  map.connect "boletas/:fid", :controller => "facturation", :action => "show_factura", :type => "b", :from => "f", :requirements => { :fid => /\d+/ }
  map.connect "cobranza/boletas/:fid", :controller => "facturation", :action => "show_factura", :type => "b", :from => "c", :requirements => { :fid => /\d+/ }
  map.connect "boletas/new", :controller => "facturation", :action => "new_factura_1", :type => "b"
  map.connect "orders/:id/boletas/new", :controller => "facturation", :action => "new_factura_2", :type => "b", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/boletas/new/:fid", :controller => "facturation", :action => "new_factura_3", :type => "b", :requirements => { :id => /\d+/, :fid => /\d+/ }
  map.connect "boletas/:fid/edit", :controller => "facturation", :action => "edit_factura", :type => "b", :requirements => { :fid => /\d+/ }
  map.connect "boletas/:fid/notas/new", :controller => "notes", :action => "new_note_1", :type => "b", :requirements => { :fid => /\d+/ }
  map.connect "boletas/:fid/notas/new/:nid", :controller => "notes", :action => "new_note_2", :type => "b", :requirements => { :fid => /\d+/, :nid => /\d+/ }
  
  
  # Facturas/Boletas
  map.connect "facturacion/:fid/void", :controller => "facturation", :action => "void_factura", :requirements => { :fid => /\d+/ }
  map.connect "facturacion/:id/remove", :controller => "facturation", :action => "delete_of", :requirements => { :id => /\d+/ }
  map.connect "facturacion/:fid/blank", :controller => "facturation", :action => "blank_factura", :requirements => { :fid => /\d+/ }
  
  # Orders (Facturaci�n)
  map.connect "orders/:id/facturacion", :controller => "facturation", :action => "order_facturation", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/facturas", :controller => "facturation", :action => "order_facturas", :type => "f", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/facturas/:fid", :controller => "facturation", :action => "show_factura", :type => "f", :from => "o", :requirements => { :id => /\d+/, :fid => /\d+/ }
  map.connect "orders/:id/facturas/new", :controller => "facturation", :action => "new_factura", :type => "f", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/facturas/:ofid/edit", :controller => "facturation", :action => "edit_factura", :type => "f", :requirements => { :id => /\d+/, :ofid => /\d+/ }
  map.connect "orders/:id/facturas/:ofid/void", :controller => "facturation", :action => "void_factura", :type => "f", :requirements => { :id => /\d+/, :ofid => /\d+/ }
  map.connect "orders/:id/boletas", :controller => "facturation", :action => "order_facturas", :type => "b", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/boletas/:fid", :controller => "facturation", :action => "show_factura", :type => "b", :from => "o", :requirements => { :id => /\d+/, :fid => /\d+/ }
  map.connect "orders/:id/boletas/new", :controller => "facturation", :action => "new_factura", :type => "b", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/boletas/:ofid/edit", :controller => "facturation", :action => "edit_factura", :type => "b", :requirements => { :id => /\d+/, :ofid => /\d+/ }
  map.connect "orders/:id/boletas/:ofid/void", :controller => "facturation", :action => "void_factura", :type => "b", :requirements => { :id => /\d+/, :ofid => /\d+/ }
  map.connect "orders/:id/facturas/:ofid/guias", :controller => "facturation", :action => "guias", :requirements => { :id => /\d+/, :ofid => /\d+/ }
  map.connect "orders/:id/facturas/:ofid/guias/:gid/edit", :controller => "facturation", :action => "edit_guia", :requirements => { :id => /\d+/, :ofid => /\d+/, :gid => /\d+/ }
  map.connect "orders/:id/facturas/:ofid/guias/:gid/delete", :controller => "facturation", :action => "delete_guia", :requirements => { :id => /\d+/, :ofid => /\d+/, :gid => /\d+/ }
  map.connect "orders/:id/facturacion/noproc.html", :controller => "facturation", :action => "non_factura", :requirements => { :id => /\d+/ }
  
  # Gu�as
  map.connect "guias/:id", :controller => "facturation", :action => "show_guia", :requirements => { :id => /\d+/ }
  map.connect "guias/:id/edit", :controller => "facturation", :action => "edit_guia", :requirements => { :id => /\d+/ }
  map.connect "guias/:id/void", :controller => "facturation", :action => "void_guia", :requirements => { :id => /\d+/ }
  map.connect "guias/find", :controller => "facturation", :action => "new_guia_1"
  map.connect "guias/page/:page", :controller => "facturation", :action => "set_guias_page", :tab => "guias", :requirements => { :page => /\d+/ }

  
  # Gu�as (Facturas)
  map.connect "facturas/:fid/guias", :controller => "facturation", :action => "factura_guias", :type => "f", :requirements => { :fid => /\d+/ }
  map.connect "facturas/:fid/guias/add", :controller => "facturation", :action => "factura_add_guias", :type => "f", :requirements => { :fid => /\d+/ }

  # Gu�as (Boletas)
  map.connect "boletas/:fid/guias", :controller => "facturation", :action => "factura_guias", :type => "b", :requirements => { :fid => /\d+/ }
  map.connect "boletas/:fid/guias/add", :controller => "facturation", :action => "factura_add_guias", :type => "b", :requirements => { :fid => /\d+/ }
  
  # Gu�as (Ordenes)
  map.connect "orders/:id/guias", :controller => "facturation", :action => "order_guias", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/guias/:serie/new", :controller => "facturation", :action => "new_guia_2", :requirements => { :id => /\d+/ }
  map.connect "orders/:id/guias/:serie/new/:number", :controller => "facturation", :action => "new_guia_3", :requirements => { :id => /\d+/ }
  
  # Notas de Cr�dito
  map.connect "notas", :controller => "notes", :action => "list"
  
  # Billing
  map.connect "cobranza/pending", :controller => "facturation", :action => "billing"
  map.connect "cobranza/pending/sort/:field", :controller => "facturation", :action => "set_billing_sort_field"
  map.connect "cobranza/panel", :controller => "facturation", :action => "billing_panel"
  map.connect "cobranza/panel/:id", :controller => "facturation", :action => "billing_panel_detail"
  map.connect "toggle_factura_confirmed/:id", :controller => "facturation", :action => "toggle_factura_confirmed"
  map.connect "accounts/:id/billing_contact", :controller => "facturation", :action => "edit_billing_contact"
  map.connect "cobranza/messenger_list", :controller => "facturation", :action => "messenger_list"
  map.connect "cobranza/invoices", :controller => "facturation", :action => "load_invoices"
  map.connect "cobranza/invoices_history", :controller => "facturation", :action => "load_history"
  
  # Categories
  map.connect "categories/", :controller => "categories", :action => "list"
  map.connect "categories/new/", :controller => "categories", :action => "new"
  map.connect "categories/:id", :controller => "categories", :action => "show", :requirements => { :id => /\d+/ }
  map.connect "categories/:id/edit", :controller => "categories", :action => "edit", :requirements => { :id => /\d+/ }
  map.connect "categories/:id/toggle_active", :controller => "categories", :action => "toggle_active", :requirements => { :id => /\d+/ }
  
  # Products
  map.connect "categories/:cid/products/new", :controller => "products", :action => "new", :requirements => { :cid => /\d+/ }
  map.connect "products/:id", :controller => "products", :action => "show", :requirements => { :id => /\d+/ }
  map.connect "products/:id/edit", :controller => "products", :action => "edit", :requirements => { :id => /\d+/ }
  map.connect "products/:id/toggle_active", :controller => "products", :action => "toggle_active", :requirements => { :id => /\d+/ }
  map.connect "products/:pid/files/:fid", :controller => "products", :action => "get_file", :requirements => { :id => /\d+/ }
  map.connect "products/:pid/files/:fid/delete", :controller => "products", :action => "delete_file", :requirements => { :id => /\d+/ }
  
  # Services
  map.connect "categories/:cid/services/new", :controller => "services", :action => "new", :requirements => { :cid => /\d+/ }
  map.connect "services/:id", :controller => "services", :action => "show", :requirements => { :id => /\d+/ }
  map.connect "services/:id/edit", :controller => "services", :action => "edit", :requirements => { :id => /\d+/ }
  map.connect "services/:id/toggle_active", :controller => "services", :action => "toggle_active", :requirements => { :id => /\d+/ }
  
  # Users
  map.connect "users/change_role", :controller => "users", :action => "change_role"
  
  # Groups
  map.connect "groups", :controller => "groups", :action => "list"
  map.connect "groups/new", :controller => "groups", :action => "new"
  map.connect "groups/:id", :controller => "groups", :action => "show"
  map.connect "groups/:id/edit", :controller => "groups", :action => "edit"
  map.connect "groups/:id/delete", :controller => "groups", :action => "delete"
  map.connect "groups/:id/add_member", :controller => "groups", :action => "add_member"
  map.connect "groups/:id/:mid/delete_member", :controller => "groups", :action => "delete_member"
  
  
  map.connect "/facturacion/accounts/auto_complete", :controller => "facturation", :action => "auto_complete_for_account_name"
  
  # Tipo de Cambio
  map.connect "tc", :controller => "tipo_de_cambio", :action => "list"
  
  # Stupid calendar library fix
  map.connect "stylesheets/menuarrow.gif", :controller => "users", :action => "menuarrow"
  
  # Accounts
  map.connect "admin/accounts/related", :controller => "accounts", :action => "related_index"
  map.connect "admin/accounts/related/:id", :controller => "accounts", :action => "related_edit"
  map.connect "admin/accounts/related/:id/delete/:rid", :controller => "accounts", :action => "related_delete"
  map.connect "/admin/accounts/auto_complete", :controller => "accounts", :action => "auto_complete_for_account_name"
  map.connect "/admin/accounts/extras", :controller => "accounts", :action => "accounts_extras"
  map.connect "/admin/accounts/extras/:id", :controller => "accounts", :action => "accounts_extras_edit"

end

