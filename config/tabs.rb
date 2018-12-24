TABS = OHash.new
TABS["dashboard"] = {
  :name        => "Inicio",
  :controller  => "dashboard",
  :action      => "index",
  :requirement => [:basic]
}
TABS["projects"] = {
  :name        => "Proyectos",
  :controller  => "projects",
  :action      => "projects",
  :requirement => [:projects]
}
TABS["orders"] = {
  :name        => "Ordenes",
  :controller  => "projects",
  :action      => "orders",
  :requirement => [:orders]
}
TABS["validate_orders"] = {
  :name        => "Validaci&oacute;n de Ordenes",
  :controller  => "projects",
  :action      => "validate_orders",
  :requirement => [:validator_tasks]
}
TABS["opportunities"] = {
  :name        => "Oportunidades",
  :controller  => "opportunities",
  :action      => "panel",
  :requirement => [:executive_tasks]
}
TABS["facturas"] = {
  :name        => "Facturas",
  :controller  => "facturation",
  :action      => "facturas",
  :requirement => [:facturation_tasks]
}
TABS["boletas"] = {
  :name        => "Boletas",
  :controller  => "facturation",
  :action      => "boletas",
  :requirement => [:facturation_tasks]
}
TABS["notes"] = {
  :name        => "Notas de Cr&eacute;dito",
  :controller  => "notes",
  :action      => "list",
  :requirement => [:facturation_tasks]
}
TABS["guias"] = {
  :name        => "Gu&iacute;as",
  :controller  => "facturation",
  :action      => "guias",
  :requirement => [:facturation_tasks]
}
TABS["billing"] = {
  :name        => "Cobranza",
  :controller  => "facturation",
  :action      => "billing_panel",
  :requirement => [:facturation_tasks]
}
TABS["reports"] = {
  :name        => "Reportes",
  :controller  => "reports",
  :action      => "index",
  :requirement => [:reports]
}
TABS["admin"] = {
  :name        => "Administraci&oacute;n",
  :controller  => "admin",
  :action      => "index",
  :requirement => [:admin, :accounts_extras]
}

