class SalidaDetalle < ActiveRecord::Base
  set_table_name "pt_Salidas_Detalle"
  belongs_to :insumo, :class_name => "InsumoItem", :foreign_key => "Cod_Ins"
end
