class Requerimiento < ActiveRecord::Base
  set_table_name "pt_Requerimientos"
  set_primary_key "cod_requerida"
  belongs_to :insumo, :class_name => "InsumoItem", :foreign_key => "cod_ins"
  
  def self.find_for_odt(oid)
    Requerimiento.find_by_sql "SELECT * FROM pt_Requerimientos WHERE cod_ot='#{oid}' AND Anula_Requerida='N' AND vinculado_compra='N'"
  end
end
