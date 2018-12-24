HEADER_NAMES = {
  "DangerFlag"                   => "&nbsp;",
  "OrdenTrabajo"                 => "Orden de Trabajo",
  "Creado"                       => "Ingreso",
  "Entrega_Diseno"               => "Entrega Dise&ntilde;o",
  "Entrega_Costos"               => "Entrega Costos",
  "Entrega_ODT"                  => "Entrega ODT",
  "PostVenta"                    => "P-Venta",
  "Entrega"                      => "Fecha de Entrega al Cliente",
  "op_creado"                    => "Creado",
  "op_recibido"                  => "Recibido",
  "op_entrega"                   => "Fecha Propuesta al Cliente",
  "Fecha_PVenta"                 => "Fecha P.Venta",
  "Estado_Diseno"                => "Estado",
  "Monto_Dolares"                => "Monto USD$",
  "Monto_Soles"                  => "Monto Soles",
  "Status_Facturacion"           => "Status Facturaci&oacute;n",
  "Status_Entrega"               => "Status Entrega",
  "Autorizado_Ejecutivo"         => "Autorizado por el Ejecutivo",
  "Dias_de_Retraso"              => "D&iacute;as de Retraso",
  "Notificar_Desarrollo"         => "Notificar (Desarrollo)",
  "Saldo_Pendiente"              => "Saldo Pendiente por Facturar",
  "FechasDeEntrega"              => "Fechas de Entrega",
  "FechasDeEntregaDescripciones" => "Descripciones",
  "TerminadoEnPlanta"            => "Terminado en Planta (Operaciones)",
  "EntregadoAlCliente"           => "Entregado al Cliente (Despacho)",
  "ReporteDeCumplimiento"        => "Reporte de Cumplimiento",
  "FechasDeEntregaMod"           => "Fechas de Entrega Modificadas por Operaciones",
  "OPFechasDeEntrega"            => "Fechas de Entrega",
}

# List of headers which are sortable
SORTABLE_HEADERS = %w(ID Propuesta Creado Estado_Diseno Entrega_Diseno Dise&ntilde;ador Entrega_Costos Cierre Entrega_ODT Ejecutivo op_creado op_recibido)

# Two-Rows Fields are special headers which span two rows
TWO_ROWS_HEADERS = %w(FechasDeEntregaDescripciones TerminadoEnPlanta EntregadoAlCliente)

# If you have headers which span columns, include them here.
COLSPAN_HEADERS = {}
COLSPAN_HEADERS["FechasDeEntregaDescripciones"] = 2
COLSPAN_HEADERS["TerminadoEnPlanta"]            = 2
COLSPAN_HEADERS["EntregadoAlCliente"]           = 3


class PanelHeader
  attr_accessor :type, :colspan, :rowspan, :sortable
  
  def initialize(f)
    @type     = f
    @colspan  = COLSPAN_HEADERS[f] || 1
    @two_rows = TWO_ROWS_HEADERS.include? f
    @sortable = SORTABLE_HEADERS.include? f
  end
  
  
  def sortable?
    return @sortable
  end
  
  
  def two_rows?
    return @two_rows
  end
  
  
  def name
    return HEADER_NAMES[self.type] || self.type
  end
  
  
  def self.invoke(list)
    return list.map do |i|
      PanelHeader.new(i)
    end
  end
  
  
  def self.length(list)
  # Calculates the total length of a series of PanelHeader elements in a
  # list, according to their colspan sizes
    return list.inject(0) { |sum, i| sum + i.colspan }
  end
end


# Panel Headers
PANEL_EXECUTIVE_PROJECTS = PanelHeader.invoke %w(ID DangerFlag Estado Propuesta Cliente Ejecutivo Creado Entrega_Diseno Entrega_Costos Cierre Area)
PANEL_EXECUTIVE_ORDERS   = PanelHeader.invoke %w(ID Propuesta Cliente Creado FechasDeEntrega FechasDeEntregaDescripciones FechasDeEntregaMod TerminadoEnPlanta EntregadoAlCliente Monto_Dolares Area Facturar PostVenta ReporteDeCumplimiento)

PANEL_CHIEF_DESIGNER = PanelHeader.invoke %w(ID DangerFlag Estado_Diseno Propuesta Cliente Ejecutivo Creado Entrega Dise&ntilde;ador Notificar Notificar_Desarrollo)
PANEL_DESIGNER       = PanelHeader.invoke %w(ID DangerFlag Estado Propuesta Cliente Ejecutivo Creado Entrega Notificar Notificar_Desarrollo)
PANEL_CHIEF_PLANNING = PanelHeader.invoke %w(ID DangerFlag Estado Propuesta Cliente Ejecutivo Creado Entrega Personal Notificar)
PANEL_PLANNER        = PanelHeader.invoke %w(ID DangerFlag Estado Propuesta Cliente Ejecutivo Creado Entrega Notificar)
PANEL_COSTS          = PanelHeader.invoke %w(ID DangerFlag Estado Propuesta Cliente Ejecutivo Creado Entrega Notificar)
PANEL_OPERATIONS     = PanelHeader.invoke %w(ID Estado Propuesta Cliente Ejecutivo op_creado op_recibido op_entrega OPFechasDeEntrega)
PANEL_FACTURATION    = PanelHeader.invoke %w(ID Propuesta Cliente Ejecutivo Creado Entrega Monto_Dolares Monto_Soles Saldo_Pendiente Status_Facturacion Status_Entrega Autorizado_Ejecutivo Dias_de_Retraso)
PANEL_INSTALLATIONS  = PanelHeader.invoke %w(ID Estado Propuesta Cliente Instalaciones_Fecha)

PANEL_ARCHIVE        = PanelHeader.invoke %w(ID Estado Propuesta OrdenTrabajo Cliente Ejecutivo Creado Entrega)
PANEL_ARCHIVE_ORDERS = PanelHeader.invoke %w(ID Estado Propuesta Cliente Creado Entrega_ODT Fecha_PVenta)

PANEL_GENERIC_PROJECTS = PanelHeader.invoke %w(ID DangerFlag Estado Propuesta Cliente Creado Entrega_Diseno Entrega_Costos Cierre Empresa)
PANEL_GENERIC_ORDERS   = PanelHeader.invoke %w(ID DangerFlag Estado Propuesta Cliente Creado Entrega_ODT)

