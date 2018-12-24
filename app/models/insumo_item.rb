class InsumoItem < ActiveRecord::Base
  set_table_name "mt_Insumos_Items"
  set_primary_key "cod_ins"
  
  def id
    return self.Cod_Ins
  end
  
  
  def proveedores
    return InsumoProveedor.find_all_by_Cod_Ins(self.Cod_Ins)
  end
  
  
  def descripcion
    return self.Dsc_Ins
  end
  
  
end
