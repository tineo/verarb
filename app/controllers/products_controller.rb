class ProductsController < ApplicationController
  before_filter :set_tab_admin
  before_filter :check_access
  
  def new
    @category = Categoria.find params[:cid]
    
    unless @category.tipo == "P"
      redirect_to :controller => "categories", :action => "list"
    else
      # Oh yeah
      @form = Fionna.new "products_new"
      
      if request.post?
        @form.load_values params
        
        if @form.valid?
          p = Producto.new({
            :nombre         => @form.nombre,
            :categoria_id   => @category.id,
            :descripcion    => @form.descripcion,
            :costo_variable => @form.costo_variable,
            :activo         => true
          })
          
          p.save
          
          # We create its directory
          FileUtils::mkdir p.path unless File.exists?(p.path)
          
          @form.atributos.split("\n").each_with_index do |a, i|
            unless a == ""
              a =~ /^([a-z]{3}) (.+?)$/
              tipo   = $1.strip
              nombre = $2.strip
              
              atributo = Atributo.new({
                :producto_id => p.id,
                :tipo        => tipo,
                :nombre      => nombre,
                :valor       => "",
                :orden       => i
              })
              
              atributo.save
            end
          end
          
          redirect_to :controller => "categories", :action => "show", :id => @category.id
        end
      end
    end
  end
  
  
  def edit
    @product = Producto.find params[:id]
    
    unless @product.activo?
      redirect_to :controller => "categories", :action => "list"
    end
    
    @files   = @product.get_files
    
    @form = Fionna.new "products_edit"
    
    if request.post?
      if params[:b] == "Aceptar"
        @form.load_values params
        
        if @form.valid?
          @product.update_attributes({
            :nombre         => @form.nombre,
            :categoria_id   => @form.categoria,
            :descripcion    => @form.descripcion,
            :costo_variable => @form.costo_variable
          })
          
          @product.update
          
          Atributo.delete_all "producto_id='" + @product.id.to_s + "'"
          
          @form.atributos.split("\n").each_with_index do |a, i|
            unless a == ""
              a =~ /^([a-z]{3}) (.+?)$/
              tipo   = $1.strip
              nombre = $2.strip
              
              atributo = Atributo.new({
                :producto_id => @product.id,
                :tipo        => $1,
                :nombre      => $2,
                :valor       => "",
                :orden       => i
              })
              
              atributo.save
            end
          end
          
          redirect_to :controller => "categories", :action => "show", :id => @product.categoria_id
        end
      elsif params[:b] == "Transferir"
        copy_data_file(params[:file], @product.path) if params[:file]
        redirect_to :action => "edit", :id => @product.id
      end
    else
      # Came from GET
      attrs = @product.atributos
      
      list = ""
      
      attrs.each do |a|
        list = list + a.tipo + " " + a.nombre + "\n"
      end
      
      
      @form.load_values({
        "nombre"         => @product.nombre,
        "categoria"      => @product.categoria_id.to_s,
        "descripcion"    => @product.descripcion,
        "costo_variable" => "%.2f" % @product.costo_variable,
        "atributos"      => list
      })
    end
  end
  
  
  def toggle_active
    p = Producto.find params[:id]
    p.activo = !p.activo?
    p.update
    
    redirect_to :controller => "categories", :action => "show", :id => p.categoria_id
  end
  
  
  def show
    @product = Producto.find params[:id]
    @attribs = @product.atributos
    @files   = @product.get_files
  end
  
  
  def get_file
    @product = Producto.find params[:pid]
    fid      = params[:fid].gsub /\//, ''
    file     = @product.path + fid
    name     = File.real_filename(fid)
    
    if params[:print] || params[:display]
      selected_width = IMAGE_PRINT_WIDTH if params[:print]
      selected_width = IMAGE_DISPLAY_WIDTH if params[:display]
      
      print_file = IMAGE_CACHE_PATH + "product-" + @product.id.to_s + "-" + selected_width.to_s + "-" + fid
      
      if File.exists?(file)
        unless File.exists?(print_file)
          width = `identify -format %w "#{file}"`.strip.to_i
          
          if width > selected_width
            `convert -geometry #{IMAGE_PRINT_WIDTH} "#{file}" "#{print_file}"`
          else
            FileUtils.copy file, print_file
          end
        end
      end
      
      file = print_file
    end
    
    if File.exists?(file)
      send_data(File.read(file),
        :filename    => name,
        :type        => "application/octet-stream",
        :disposition => "attachment; filename=" + name)
    end
  end
  
  
  def delete_file
    @product = Producto.find params[:pid]
    delete_data_file(@product.path, params[:fid])
    
    redirect_to :action => "edit", :id => @product.id
  end

end
