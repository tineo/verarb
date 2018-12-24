E_NUEVO                        = 1
E_DISENO_EN_PROCESO            = 2
E_DISENO_SIN_ASIGNAR           = 3
E_DISENO_POR_APROBAR           = 4
E_DISENO_OBSERVADO             = 5
E_DISENO_APROBADO              = 6
E_PLANEAMIENTO_SIN_ASIGNAR     = 7
E_PLANEAMIENTO_POR_APROBAR     = 8
E_PLANEAMIENTO_EN_PROCESO      = 9
E_PLANEAMIENTO_OBSERVADO       = 10
E_PLANEAMIENTO_TERMINADO       = 11
E_COSTOS_EN_PROCESO            = 12
E_COSTOS_TERMINADO             = 13
E_OPERACIONES_EN_PROCESO       = 14
E_OPERACIONES_POR_APROBAR_EX   = 15 # Not used anymore
E_OPERACIONES_POR_APROBAR_OP   = 16 # Not used anymore
E_OPERACIONES_TERMINADO        = 17
E_OPERACIONES_REDEF_WAITING_OP = 18 # Not used anymore
E_OPERACIONES_REDEF_WAITING_EX = 19 # Not used anymore
E_OPERACIONES_EN_MODIFICACION  = 23
E_INNOVACIONES_EN_PROCESO      = 20
E_INSTALACIONES_EN_PROCESO     = 21
E_INSTALACIONES_TERMINADO      = 22
E_TERMINADO                    = 100
E_PERDIDO                      = 101
E_ANULADO                      = 102

# If you add a new Status you might want to add it to the options list of
# the filter in Fionna's application.rb (status_options) and also to the
# processing code in projects_controller::core

ESTADOS = {
  E_NUEVO => {
    :label     => "Nuevo",
    :color_off => "#F6F1A8",
    :color_on  => "#FFFAAE"
  },
  
  E_DISENO_EN_PROCESO => {
    :label     => "Dise&ntilde;o en proceso",
    :color_off => "#C4E5F0",
    :color_on  => "#CBEDF9"
  },
  
  E_DISENO_SIN_ASIGNAR => {
    :label     => "Dise&ntilde;o sin asignar",
    :color_off => "#C4E5F0",
    :color_on  => "#CBEDF9"
  },
  
  E_DISENO_POR_APROBAR => {
    :label     => "Dise&ntilde;o por aprobar",
    :color_off => "#C4E5F0",
    :color_on  => "#CBEDF9"
  },
  
  E_DISENO_OBSERVADO => {
    :label     => "Dise&ntilde;o observado",
    :color_off => "#C4E5F0",
    :color_on  => "#CBEDF9"
  },
  
  E_DISENO_APROBADO => {
    :label     => "Dise&ntilde;o aprobado",
    :color_off => "#C4E5F0",
    :color_on  => "#CBEDF9"
  },
  
  E_PLANEAMIENTO_SIN_ASIGNAR => {
    :label     => "D&D sin asignar",
    :color_off => "#F2A074",
    :color_on  => "#FBA678"
  },
  
  E_PLANEAMIENTO_EN_PROCESO => {
    :label     => "D&D en proceso",
    :color_off => "#F2A074",
    :color_on  => "#FBA678"
  },
  
  E_PLANEAMIENTO_POR_APROBAR => {
    :label     => "D&D por aprobar",
    :color_off => "#F2A074",
    :color_on  => "#FBA678"
  },
  
  E_PLANEAMIENTO_OBSERVADO => {
    :label     => "D&D observado",
    :color_off => "#F2A074",
    :color_on  => "#FBA678"
  },
  
  E_PLANEAMIENTO_TERMINADO => {
    :label     => "D&D terminado",
    :color_off => "#F2A074",
    :color_on  => "#FBA678"
  },
  
  E_COSTOS_EN_PROCESO => {
    :label     => "Costos en proceso",
    :color_off => "#C5F694",
    :color_on  => "#CCFF99"
  },
  
  E_COSTOS_TERMINADO => {
    :label     => "Costos terminado",
    :color_off => "#C5F694",
    :color_on  => "#CCFF99"
  },
  
  E_OPERACIONES_EN_PROCESO => {
    :label     => "Fecha en proceso",
    :color_off => "#BBAACD",
    :color_on  => "#C3B1D5"
  },
  
  E_OPERACIONES_POR_APROBAR_EX => {
    :label     => "Fecha por aprobar Ej.",
    :color_off => "#EEB8D0",
    :color_on  => "#F8BFD8"
  },
  
  E_OPERACIONES_POR_APROBAR_OP => {
    :label     => "Fecha por aprobar Op.",
    :color_off => "#BBAACD",
    :color_on  => "#C3B1D5"
  },
  
  E_OPERACIONES_TERMINADO => {
    :label     => "Operaciones terminado",
    :color_off => "#D07C9E",
    :color_on  => "#D981A4"
  },
  
  E_OPERACIONES_REDEF_WAITING_OP => {
    :label     => "Esperando aut. Op. nueva Fecha",
    :color_off => "#EEB8D0",
    :color_on  => "#F8BFD8"
  },
  
  E_OPERACIONES_REDEF_WAITING_EX => {
    :label     => "Esperando aut. Ej. nueva Fecha",
    :color_off => "#EEB8D0",
    :color_on  => "#F8BFD8"
  },
  
  E_OPERACIONES_EN_MODIFICACION => {
    :label     => "En Modificaci&oacute;n",
    :color_off => "#EEB8D0",
    :color_on  => "#F8BFD8"
  },
  
  E_INNOVACIONES_EN_PROCESO => {
    :label     => "Innovaciones en proceso",
    :color_off => "#FF92D2",
    :color_on  => "#FFADDD"
  },
  
  E_INSTALACIONES_EN_PROCESO => {
    :label     => "Instalaciones en proceso",
    :color_off => "#d2d2d2",
    :color_on  => "#adadad"
  },
  
  E_INSTALACIONES_TERMINADO => {
    :label     => "Instalaciones terminado",
    :color_off => "#d2d2d2",
    :color_on  => "#adadad"
  },
  
  E_TERMINADO => {
    :label     => "Cerrado Triunfo",
    :color_off => "#eeeeee",
    :color_on  => "#f7f7f7"
  },
  
  E_PERDIDO => {
    :label     => "Cerrado Derrota",
    :color_off => "#f67075",
    :color_on  => "#ff7479"
  },
  
  E_ANULADO => {
    :label     => "ODT anulada",
    :color_off => "#f67075",
    :color_on  => "#ff7479"
  },
}


STATUS_ENTREGA = OHash.new
STATUS_ENTREGA["1"] = "Entregado al Cliente"
STATUS_ENTREGA["0"] = "No entregado"


F_POR_FACTURAR    = "0"
F_FACTURA_PARCIAL = "2"
F_FACTURA_TOTAL   = "1"
F_NO_FACTURABLE   = "99"

ODT_STATUS_FACTURACION = OHash.new
ODT_STATUS_FACTURACION[F_POR_FACTURAR]    = "Pendiente por Facturar"
ODT_STATUS_FACTURACION[F_FACTURA_PARCIAL] = "Facturado parcial"
ODT_STATUS_FACTURACION[F_FACTURA_TOTAL]   = "Facturado total"


C_POR_COBRAR      = "0"
C_COBRADO         = "1"

ODT_STATUS_COBRANZA = OHash.new
ODT_STATUS_COBRANZA[C_POR_COBRAR] = "Pendiente por Cobrar"
ODT_STATUS_COBRANZA[C_COBRADO]    = "Cobrado"

# Fechas de Entrega
FECHAS_DE_ENTREGA_PENDIENTE                 = 0 # Not used anymore
FECHAS_DE_ENTREGA_ACEPTADO                  = 1
FECHAS_DE_ENTREGA_POR_APROBAR_EX            = 2
FECHAS_DE_ENTREGA_POR_APROBAR_OP            = 3
FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_EX = 4
FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_OP = 5

FECHAS_DE_ENTREGA = OHash.new
FECHAS_DE_ENTREGA[FECHAS_DE_ENTREGA_PENDIENTE]                 = "Pendiente"
FECHAS_DE_ENTREGA[FECHAS_DE_ENTREGA_ACEPTADO]                  = "Aceptado"
FECHAS_DE_ENTREGA[FECHAS_DE_ENTREGA_POR_APROBAR_EX]            = "Por aprobar Ejecutivo"
FECHAS_DE_ENTREGA[FECHAS_DE_ENTREGA_POR_APROBAR_OP]            = "Por aprobar Operaciones"
FECHAS_DE_ENTREGA[FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_EX] = "Por aprobar Modificaci&oacute;n Ejecutivo"
FECHAS_DE_ENTREGA[FECHAS_DE_ENTREGA_MODIFICADO_POR_APROBAR_OP] = "Por aprobar Modificaci&oacute;n Operaciones"


