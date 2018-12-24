PERMISOS = [
  [:projects, "Proyectos",
  "Acceso al panel de Proyectos y ver los datos y detalle de los Proyectos."],
  
  [:orders, "Ordenes",
  "Acceso al panel de Ordenes y ver los datos y detalle de las Ordenes."],
  
  [:executive_tasks, "Tareas de Ejecutivo de Cuentas",
  "Tareas propias de los Ejecutivos de Cuentas. El Vera considera a un usuario como de tipo Ejecutivo de Cuentas si su Rol incluye este permiso."],
  
  [:design, "Dise&ntilde;o",
  "Puede entrar y ver los datos del Area de Dise&ntilde;o de un Proyecto u Orden."],
  
  [:design_development, "Dise&ntilde;o/Desarrollo",
  "Puede entrar y ver la intereacci&oacute;n entre Dise&ntilde;o y Desarrollo de un Proyecto u Orden."],
  
  [:designer_tasks, "Tareas de Dise&ntilde;ador",
  "Tareas propias de los Dise&ntilde;adores. El Vera considera a un usuario como de tipo Dise&ntilde;ador si su Rol incluye este permiso."],
  
  [:chief_designer_tasks, "Tareas de Jefe de Dise&ntilde;o",
  "Tareas propias de los Jefes de Dise&ntilde;o. El Vera considera a un usuario como de tipo Jefe de Dise&ntilde;o si su Rol incluye este permiso."],
  
  [:planning, "Planeamiento",
  "Puede entrar y ver los datos del Area de Planeamiento de un Proyecto u Orden."],
  
  [:planner_tasks, "Tareas de Personal de Planeamiento",
  "Tareas propias del Personal de Planeamiento. El Vera considera a un usuario como de tipo Planeamiento si su Rol incluye este permiso."],
  
  [:chief_planning_tasks, "Tareas de Jefe de Planeamiento",
  "Tareas propias de los Jefes de Planeamiento. El Vera considera a un usuario como de tipo Jefe de Planeamiento si su Rol incluye este permiso."],
  
  [:costs, "Costos",
  "Puede entrar y ver los datos del Area de Costos de un Proyecto u Orden."],
  
  [:costs_tasks, "Tareas de Costos",
  "Tareas propias de Costos. El Vera considera a un usuario como de tipo Costos si su Rol incluye este permiso."],
  
  [:operations_mob_tasks, "Tareas de Operaciones - Mobiliario",
  "Acceso al Area de Operaciones y tareas propias de personal de Operaciones - Mobiliario. El Vera considera a un usuario como de tipo Operaciones - Mobiliario si su Rol incluye este permiso."],
  
  [:operations_arq_tasks, "Tareas de Operaciones - Arquitectura",
  "Acceso al Area de Operaciones y tareas propias de personal de Operaciones - Arquitectura. El Vera considera a un usuario como de tipo Operaciones - Arquitectura si su Rol incluye este permiso."],
  
  [:facturation_tasks, "Tareas de Facturaci&oacute;n",
  "Acceso al Area de Facturas, paneles de Facturas, Boletas, Gu&iacute;as y tareas propias de personal de Facturaci&oacute;n. El Vera considera a un usuario como de tipo Facturaciones si su Rol incluye este permiso."],
  
  [:chief_development_tasks, "Tareas de Jefe de Desarrollo",
  "Acceso como Jefe de Desarrollo. El Vera considera a un usuario como de tipo Jefe de Desarrollo si su Rol incluye este permiso."],
  
  [:development_tasks, "Tareas de Desarrollo",
  "Acceso como Usuario de Desarrollo. El Vera considera a un usuario como de tipo Desarrollo si su Rol incluye este permiso."],
  
  [:printviewer_tasks, "Visor de ODT impresa",
  "S&oacute;lo lectura a la ODT impresa"],
  
  [:op_supervisor, "Supervisor Operaciones",
  "El Vera considera a un usuario un Supervisor de Operaciones a los usuarios con este permiso."],
  
  [:commercial_manager, "Gerente Comercial",
  "El Vera considera a un usuario como Gerente Comercial a aquellos que tengan este permiso."],
  
  [:cotizations, "Cotizaciones", "Vista de sólo lectura a Cotizaciones."],
  
  [:accounts_extras, "Datos de Facturaci&oacute;n de Clientes",
  "Administraci&oacute;n de datos complementarios de Facturaci&oacute;n de Clientes creados en el CRM."],
  
  [:innovations, "Innovaciones",
  "Puede entrar y ver los datos del Area de Innovaciones de un Proyecto u Orden."],
  
  [:innovations_tasks, "Tareas de Innovaciones",
  "Tareas propias de Innovaciones. El Vera considera a un usuario como de tipo Innovaciones si su Rol incluye este permiso."],
  
  [:validator_tasks, "Tareas del Encargado de Validaci&oacute;n de Ordenes",
  "El Vera considera a un usuario como de tipo Encargado de Validaci&oacute;n de Ordenes si su Rol incluye este permiso."],
  
  [:operations_validator_tasks, "Tareas del Encargado de Validaci&oacute;n de Operaciones",
  "El Vera considera a un usuario como de tipo Encargado de Validaci&oacute;n de Operaciones si su Rol incluye este permiso."],
  
  [:installations, "Instalaciones",
  "Puede entrar y ver los datos del Area de Instalaciones de un Proyecto u Orden."],
  
  [:installations_tasks, "Tareas de Instalaciones",
  "Tareas propias de Instalaciones. El Vera considera a un usuario como de tipo Instalaciones si su Rol incluye este permiso."],
  
  [:production, "Producci&oacute;n",
  "Puede entrar y ver los datos del Area de Producci&oacute;n de un Proyecto u Orden."],
  
  [:production_tasks, "Tareas de Producci&oacute;n",
  "Tareas propias de Producci&oacute;n. El Vera considera a un usuario como de tipo Producci&oacute;n si su Rol incluye este permiso."],
  
  [:reports, "Reportes",
  "Acceso al panel de Reportes."],
  
  [:reports_ventas, "Reporte de Ventas",
  "Acceso al Reporte de Ventas."],
  
  [:reports_monthly, "Reporte de Venta Mensual",
  "Acceso al Reporte de Venta Mensual."],
  
  [:reports_account_movement, "Reporte de Movimiento de Cuentas",
  "Acceso al Reporte de Movimiento de Cuentas."],
  
  [:reports_commercial_briefing, "Reporte de Resumen Comercial",
  "Acceso al Reporte de Resumen Comercial."],
  
  [:reports_design, "Reporte por Costo de Oportunidad",
  "Acceso al Reporte por Costo de Oportunidad."],
  
  [:reports_flow, "Reporte de Flujo de Cobranza",
  "Acceso a dicho Reporte."],
  
  [:reports_truput_estimado_mes, "Reporte de Truput Estimado por Mes",
  "Acceso a dicho Reporte."],
  
  [:reports_estimado_cierre_de_venta, "Reporte Estimado por Cierre de Venta",
  "Acceso a dicho Reporte."],
  
  [:reports_odt_guia, "Reporte de ODTs con Gu&iacute;as y Facturas no Relacionadas",
  "Acceso a dicho Reporte."],
  
  [:reports_costos_por_odt, "Reporte de Costos por ODT",
  "Acceso a dicho Reporte."],
  
  [:reports_resumen_truput_mensual, "Reporte de Resumen de Truput Mensual",
  "Acceso a dicho Reporte."],
  
  [:reports_otras_variables, "Reporte de Otras Variables",
  "Acceso a dicho Reporte."],
  
  [:reports_odts_sin_fecha_cierre, "Reporte de ODTs sin Fecha de Cierre",
  "Acceso a dicho Reporte."],
  
]
