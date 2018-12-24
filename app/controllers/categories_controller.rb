class CategoriesController < ApplicationController
  before_filter :set_tab_admin
  before_filter :check_access
  
  def list
    @prod_cats = Categoria.find_all_by_tipo "P", :order => "nombre"
    @serv_cats = Categoria.find_all_by_tipo "S", :order => "nombre"
  end
  
  
  def new
    @form = Fionna.new "categories_new"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        c = Categoria.new({
          :nombre      => @form.nombre,
          :tipo        => @form.tipo,
          :descripcion => @form.descripcion,
          :activo      => true
        })
        
        c.save
        
        redirect_to :action => "list"
      end
    end
  end
  
  
  def edit
    @category = Categoria.find params[:id]
    
    unless @category.activo?
      redirect_to :controller => "categories", :action => "list"
    end
    
    @form = Fionna.new "categories_new"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        @category.update_attributes({
          :nombre => @form.nombre,
          :tipo   => @form.tipo
        })
        
        @category.update
        
        redirect_to :action => "list"
      end
    else
      @form.load_values({
        "nombre" => @category.nombre,
        "tipo"   => @category.tipo
      })
    end
  end
  
  
  def toggle_active
    c = Categoria.find params[:id]
    c.activo = !c.activo?
    c.update
    
    redirect_to :action => "list"
  end
  
  
  def show
    @category = Categoria.find params[:id]
    if @category.tipo == "P"
      @children = Producto.find_all_by_categoria_id @category.id, :order => "nombre"
      @children_controller = "products"
      @what = "producto"
    else
      @children = Servicio.find_all_by_categoria_id @category.id, :order => "nombre"
      @children_controller = "services"
      @what = "servicio"
    end
  end
end
