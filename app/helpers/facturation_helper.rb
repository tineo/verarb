module FacturationHelper
  def guia_facturada_status(g)
    if g.facturada?
      return image_tag("stock_ok-16.gif", :alt => "SI")
    else
      return ""
    end
  end
end
