class RolesController < ApplicationController
  before_filter :set_tab_admin
  before_filter :check_access
  
  def list
    @roles = Rol.find :all, :order => "name"
  end
  
  
  def new
    @form   = Fionna.new "roles_admin"
    @allows = []
    
    if request.post?
      @allows = params[:allows] if params[:allows]
      
      @form.load_values params
      
      if @form.valid?
        r             = Rol.new
        r.name        = @form.name
        r.description = @form.description
        r.save
        
        @allows.each do |a|
          p         = Permiso.new
          p.rol_id  = r.id
          p.permiso = a
          p.save
        end
        
        redirect_to :action => "list"
      end
    end
  end
  
  
  def edit
    @role = Rol.find params[:id]
    
    @form   = Fionna.new "roles_admin"
    @form.load_values @role.attributes
    
    @allows = []
    
    if request.post?
      @allows = params[:allows] if params[:allows]
      
      @form.load_values params
      
      if @form.valid?
        @role.name        = @form.name
        @role.description = @form.description
        @role.save
        
        Permiso.destroy_all "rol_id='#{params[:id]}'"
        
        @allows.each do |a|
          p         = Permiso.new
          p.rol_id  = @role.id
          p.permiso = a
          p.save
        end
        
        redirect_to :action => "list"
      end
    else
      allows = Permiso.find :all, :conditions => "rol_id='#{@role.id}'"
      
      allows.each do |a|
        @allows << a.permiso
      end
      
    end
  end
  
  
  def delete
    Rol.destroy params[:id]
    Permiso.destroy_all "rol_id='#{params[:id]}'"
    UsuariosRoles.destroy_all "rol_id='#{params[:id]}'"
    
    redirect_to :action => "list"
  end
  
  
  def user_list
    @users = User.full_list
  end
  
  
  def user_edit
    @user  = User.find params[:id]
    @roles = UsuariosRoles.find_all_by_user_id @user.id
    
    @form  = Fionna.new "roles_user"
    @emp   = Fionna.new "roles_user_companies"
    
    if request.post?
      if params[:add]
        # Trying to add a Role?
        @form.load_values params
        
        if @form.valid?
          list = []
          @roles.each do |r|
            list << r.rol_id
          end
          
          unless list.include? params[:role].to_i
            ur = UsuariosRoles.new
            ur.user_id = @user.id
            ur.rol_id  = params[:role]
            ur.save
          end
          
          redirect_to :action => "user_edit", :id => params[:id]
        end
      
      elsif params[:emp]
        # Trying to update the Companies of this user?
        @emp.load_values params
        
        if @emp.valid?
          EmpresaUser.destroy_all "user_id='#{@user.id}'"
          
          @emp.empresas.each do |e|
            eu = EmpresaUser.new({
              :user_id    => @user.id,
              :empresa_id => e
            })
            eu.save
          end
          
          redirect_to :action => "user_edit", :id => params[:id]
        end
        
      else
        @user.is_vera_supervisor  = !params[:supervisor].nil?
        @user.is_vera_admin       = !params[:admin].nil?
        @user.has_external_access = !params[:external].nil?
        @user.save
        
        redirect_to :action => "user_edit", :id => params[:id]
      end
    else
      if params[:delete]
        UsuariosRoles.destroy(params[:delete])
        redirect_to :action => "user_edit", :id => params[:id]
      end
      
      @emp.empresas = @user.companies.collect { |c| c.empresa_id.to_s }
    end
  end
end
