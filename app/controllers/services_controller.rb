class ServicesController < ApplicationController
  before_filter :set_tab_admin
  before_filter :check_access
  
  def new
    @category = Categoria.find params[:cid]
    
    unless @category.tipo == "S"
      redirect_to :controller => "categories", :action => "list"
    else
      # Oh yeah
      @form = Fionna.new "services_new"
      
      if request.post?
        @form.load_values params
        
        if @form.valid?
          s = Servicio.new({
            :nombre       => @form.nombre,
            :categoria_id => @category.id,
            :descripcion  => @form.descripcion,
            :activo       => true
          })
          
          s.save
          
          redirect_to :controller => "categories", :action => "show", :id => @category.id
        end
      end
    end
  end
  
  
  def edit
    @service = Servicio.find params[:id]
    
    unless @service.activo?
      redirect_to :controller => "categories", :action => "list"
    end
    
    @form = Fionna.new "services_edit"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        @service.update_attributes({
          :nombre       => @form.nombre,
          :categoria_id => @form.categoria,
          :descripcion  => @form.descripcion
        })
        
        @service.update
        
        redirect_to :controller => "categories", :action => "show", :id => @service.categoria_id
      end
    else
      @form.load_values({
        "nombre"       => @service.nombre,
        "categoria"    => @service.categoria_id.to_s,
        "descripcion"  => @service.descripcion
      })
    end
  end
  
  
  def toggle_active
    s = Servicio.find params[:id]
    s.activo = !s.activo?
    s.update
    
    redirect_to :controller => "categories", :action => "show", :id => s.categoria_id
  end
  
  
  def show
    @service = Servicio.find params[:id]
  end
end
