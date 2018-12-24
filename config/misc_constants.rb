# From these IPs we generate URLs (see app/helpers/application_helper.rb)
EXTERNAL_IP = "190.41.183.249"
INTERNAL_IP = "192.168.10.1"

# SQL condition to identify deleted Opportunities (as Vera sees them -- read
# hacks-al-sugar.txt)
SQL_VERA_DELETED = "(opportunities.deleted='1' AND opportunities.used_in_vera='0')"

REPORT_COLORS = ["7A3752", "DFAB1F", "DF441F", "3A9951", "A2339F", "D47A48", "047082", "0D5BA8", "FF1DA2", "FF1DA2", "FF1DA2", "FF1DA2", "FF1DA2"]

# Bindings to the CRM -- be careful!
CRM_CURRENCY_SOLES   = "af38fd5c-537c-4caf-7330-4653baa285a9"
CRM_CURRENCY_DOLARES = "-99"
  
PASSWORDS_PATH     = RAILS_ROOT + "/config/passwords.yaml"
PRODUCTS_PATH      = RAILS_ROOT + "/data/products/"
PROJECTS_PATH      = RAILS_ROOT + "/data/projects/"
COSTS_PATH         = RAILS_ROOT + "/data/costs/"
DOCS_PATH          = RAILS_ROOT + "/data/docs/"
INNOVATIONS_PATH   = RAILS_ROOT + "/data/innovations/"
INSTALLATIONS_PATH = RAILS_ROOT + "/data/installations/"
IMAGE_CACHE_PATH   = RAILS_ROOT + "/data/image_cache/"
PDF_PATH           = RAILS_ROOT + "/data/pdf/"
FORMULARIOS_PATH   = RAILS_ROOT + "/data/formularios/"

PDF_FONT         = PDF_PATH + "VeraMono.ttf" #"ProFontWindows.ttf" #"slkscr.ttf"
PDF_FONT_SIZE    = 10

MAIL_LOCK_FILE   = "/tmp/VERA-MAIL-LOCK"

if ENV['RAILS_ENV'] == 'production'
  BUDGET_EXPORT_PATH = "/data/sdb1/data/bdapoyo/SISPRE/logs/"
else
  BUDGET_EXPORT_PATH = "/tmp/vera/"
end

IMAGE_PRINT_WIDTH   = 320
IMAGE_DISPLAY_WIDTH = 480

EMAIL_FROM_NAME    = "Sistema Apoyo"
EMAIL_FROM_ADDRESS = "notificaciones@apoyopublicitario.com"

NIVEL_SEGURIDAD = []
NIVEL_SEGURIDAD[1]  = "Bajo"
NIVEL_SEGURIDAD[2]  = "Alto"
NIVEL_SEGURIDAD[3]  = "Muy alto"

APOYO        = 0
ARQUITECTURA = 1
CONSORCIO    = 2
DIRECCION    = 3
TISAC        = 4

EMPRESA_VENDEDORA = []
EMPRESA_VENDEDORA[0] = "Consorcio de Apoyo Publicitario SAC"
EMPRESA_VENDEDORA[1] = "Consorcio de Arquitectura Comercial SAC"
EMPRESA_VENDEDORA[2] = "Consorcio de Direcci&oacute;n Empresarial SAC"
EMPRESA_VENDEDORA[3] = "Estrategia y Direcci&oacute;n EIRL"
EMPRESA_VENDEDORA[4] = "Tecnolog�a Interactiva S.A.C."

EMPRESA_VENDEDORA_SHORT = []
EMPRESA_VENDEDORA_SHORT[0] = "APY"
EMPRESA_VENDEDORA_SHORT[1] = "ARQ"
EMPRESA_VENDEDORA_SHORT[2] = "DIR"
EMPRESA_VENDEDORA_SHORT[3] = "EST"
EMPRESA_VENDEDORA_SHORT[4] = "TEC"

EMPRESA_VENDEDORA_RUC = []
EMPRESA_VENDEDORA_RUC[0] = "20514611697"
EMPRESA_VENDEDORA_RUC[1] = "20514612588"
EMPRESA_VENDEDORA_RUC[2] = "20505144989"
EMPRESA_VENDEDORA_RUC[3] = "20513906367"
EMPRESA_VENDEDORA_RUC[4] = "20492343413"

TIPO_DE_VENTA = []
TIPO_DE_VENTA[0] = "Arquicom"
TIPO_DE_VENTA[1] = "BTL"
TIPO_DE_VENTA[2] = "Comex"
TIPO_DE_VENTA[3] = "Stands"
TIPO_DE_VENTA[4] = "Trade"
TIPO_DE_VENTA[5] = "Mantenimiento"
TIPO_DE_VENTA[6] = "Otros"
TIPO_DE_VENTA[7] = "Innovaciones"
TIPO_DE_VENTA[8] = "MattePeru"

T_NUEVO_PROYECTO = 0
T_GARANTIA       = 1
T_RECLAMO        = 2
T_ORDEN_INTERNA  = 3
T_OTRO           = 4

TIPO_PROYECTO = OHash.new
TIPO_PROYECTO[T_NUEVO_PROYECTO] = "Nuevo proyecto"
TIPO_PROYECTO[T_GARANTIA]       = "Garant&iacute;a"
TIPO_PROYECTO[T_RECLAMO]        = "Reclamo"
TIPO_PROYECTO[T_ORDEN_INTERNA]  = "Orden Interna"
TIPO_PROYECTO[T_OTRO]           = "Otro"

SUBTIPO_NUEVO_PROYECTO_MOBILIARIO   = 0
SUBTIPO_NUEVO_PROYECTO_ARQUITECTURA = 1

TIPO_DE_PRESENTACION = OHash.new
TIPO_DE_PRESENTACION["simple"]      = "Simple"
TIPO_DE_PRESENTACION["fotomontaje"] = "Fotomontaje"
TIPO_DE_PRESENTACION["powerpoint"]  = "Powerpoint"
TIPO_DE_PRESENTACION["flash"]       = "Flash"
TIPO_DE_PRESENTACION["otro"]        = "Otro"

OP_DATE_REDEF_SOLICITADO_POR   = OHash.new
OP_DATE_REDEF_SOLICITADO_POR["0"] = "Cliente"
OP_DATE_REDEF_SOLICITADO_POR["1"] = "Empresa"

# Notification List for defining which recipients receive them via mail
NOTIFICACION = OHash.new
NOTIFICACION["void_odt"]                  = "Anulaci&oacute;n de ODT"
NOTIFICACION["urgent_design"]             = "Dise&ntilde;o Urgente"
NOTIFICACION["urgent_planning"]           = "Planeamiento Urgente"
NOTIFICACION["urgent_costs"]              = "Costos Urgente"
NOTIFICACION["internal_odt"]              = "ODT Interna"
NOTIFICACION["odt_amount_change"]         = "Cambio de precio ODT"
NOTIFICACION["product_qty_change"]        = "Cambio de cantidad de Producto"
NOTIFICACION["op_date_confirm_mob"]       = "Fecha de Entrega (Mobiliario)"
NOTIFICACION["op_date_confirm_arq"]       = "Fecha de Entrega (Arquitectura)"
NOTIFICACION["odt_invoice"]               = "Orden autorizada para facturar"
NOTIFICACION["redefine_facturated_price"] = "Cambio de Precio de ODT facturada"
NOTIFICACION["odt_in_standby"]            = "ODT en Standby"
NOTIFICACION["insumos_percent"]           = "Alerta suma de Insumos"
NOTIFICACION["installations_observation"] = "Observaci&oacute;n de Instalaciones"
NOTIFICACION["op_date_data_modified"]     = "Datos de Fecha de Entrega modificados"

# Notifications types used in Vera
NOTIFICACIONES = OHash.new
NOTIFICACIONES["MNSJ"]        = "Mensaje"
NOTIFICACIONES["ASIGN"]       = "Asignaci&oacute;n de Personal"
NOTIFICACIONES["NUEVO"]       = "Enviado a Area"
NOTIFICACIONES["CANTPR"]      = "Modificaci�n de Cantidad de Productos"
NOTIFICACIONES["INTER"]       = "Marcado como Orden Interna"
NOTIFICACIONES["NOTIF"]       = "Notificaci�n a Area"
NOTIFICACIONES["OBSV"]        = "Proyecto Observado"
NOTIFICACIONES["DIAP"]        = "Dise&ntilde;o aprobado"
NOTIFICACIONES["DIDE"]        = "Dise&ntilde;o enviado a Desarrollo"
NOTIFICACIONES["URGT"]        = "Marcado como Urgente"
NOTIFICACIONES["ANULA"]       = "Anulado"
NOTIFICACIONES["INTER"]       = "Orden Interna"
NOTIFICACIONES["ODTCM"]       = "Monto de Venta modificado"
NOTIFICACIONES["ODTCG"]       = "Monto de Venta modificado posterior a firma de Gu&iacute;a final"
NOTIFICACIONES["OFACT"]       = "Autorizado para Facturar"
NOTIFICACIONES["FENTROKOP"]   = "Fecha de Entrega aceptada por Operaciones"
NOTIFICACIONES["FENTROKEXEC"] = "Fecha de Entrega aceptada por Ejecutivo"
NOTIFICACIONES["FENTRREEXEC"] = "Fecha de Entrega replanteada por Ejecutivo"
NOTIFICACIONES["FENTRREOP"]   = "Fecha de Entrega replanteada por Operaciones"
NOTIFICACIONES["FENTRMO"]     = "Fecha de Entrega modificada"
NOTIFICACIONES["FENTRMA"]     = "Fecha de Entrega esperando aprobaci&oacute;n"
NOTIFICACIONES["FENTRDE"]     = "Fecha de Entrega rechazada"
NOTIFICACIONES["FENTRMO"]     = "Datos de Fecha de Entrega modificados"
NOTIFICACIONES["ODTFPRE"]     = "Cambio de Precio de ODT facturada (pendiente)"
NOTIFICACIONES["ODTFPOK"]     = "Cambio de Precio de ODT facturada (aprobada)"
NOTIFICACIONES["ODTSBTA"]     = "ODT marcada en Standby"
NOTIFICACIONES["ODTSBTB"]     = "ODT desmarcada en Standby"
NOTIFICACIONES["INSUMO"]      = "Alerta suma de Insumos"

NEW_GUIA_SERIES       = OHash.new
NEW_GUIA_SERIES["1"]  = "001"
NEW_GUIA_SERIES["2"]  = "002"

E_VALIDACION_POR_CREAR   = "0"
E_VALIDACION_POR_APROBAR = "1"
E_VALIDACION_RECHAZADO   = "2"
E_VALIDACION_APROBADO    = "3"

E_VALIDACION = OHash.new
E_VALIDACION[E_VALIDACION_POR_CREAR]   = "Por Crear"
E_VALIDACION[E_VALIDACION_POR_APROBAR] = "Por Aprobar"
E_VALIDACION[E_VALIDACION_RECHAZADO]   = "Rechazado"
E_VALIDACION[E_VALIDACION_APROBADO]    = "Aprobado"

