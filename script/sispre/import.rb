#!/usr/bin/ruby
#
# This script imports the SISPRE data to Vera's DB
# Starts by re-creating each table and then reading the data from the MDB file.
# Requires "mdbtools" installed.

require 'fileutils'

mdb = '/data/sdb1/data/bdapoyo/SISPRE/BD_SISPRE.mdb'
#mdb = '/home/clients/Apoyo/SISPRE/BD_SISPRE.mdb'

c = FileUtils.getwd
FileUtils.chdir "/var/www/app/script/sispre/"
#FileUtils.chdir "/home/clients/Apoyo/Vera/src/devel/script/sispre/"

mysql = "mysql -u apoyocrm -psug4rap0y0 crm2"

puts "Dropping and recreating tables..."
system("cat sql-tables.txt | #{mysql}")

puts "Ok, go go go!"

["mt_Tipos_Cambio", "mt_Insumos_Items", "mt_Insumos_Proveedores", "pt_Salidas_Detalle", "pt_Salidas_Cabecera", "pt_Servicios_Items", "pt_Servicios_Cabecera", "pt_OT_Cabecera", "pt_Compras_Libres_Cabecera", "pt_Compras_Libres_Detalle", "mt_Areas", "mt_Cuentas_Servicios", "mt_Tipos_Documentos", "mt_Trabajadores", "mt_Usuarios_Cajas", "pt_Compras_Cabecera", "pt_Compras_Detalle"].each do |f|
  puts "- #{f}" 
  system("/usr/local/bin/mdb-export -I -q \\' #{mdb} #{f} | /usr/bin/ruby filter.rb | #{mysql}")
end

FileUtils.chdir c

puts "Done!"


