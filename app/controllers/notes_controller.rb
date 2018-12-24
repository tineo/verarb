class NotesController < ApplicationController
  before_filter :set_tab
  before_filter :preload_factura, :only => ["new_note_1", "new_note_2"]
  before_filter :preload_note, :only => ["show", "edit", "void"]
  before_filter :check_access
  
  def set_tab
    set_current_tab "notes"
  end
  
  
  def list
    conditions = ""
    
    @docs = NotaDeCredito.find_by_sql "
      SELECT *
        FROM notas_de_creditos
       WHERE empresa IN #{companies_sql_list}
             #{conditions}
    ORDER BY empresa,
             numero DESC";
  end
  
  
  def new_note_1
    get_facturation_document_type_for_notes
    empresa = @factura.empresa
    
    @curr = NoteNumber.peek_next(@type, empresa)
    @numbers = NotaDeCredito.find_usable_for_new(@type, empresa)
    
    if request.post?
      if params[:reserve]
        NoteNumber.reserve_next_as_blank(@type, empresa)
        redirect_to :action => "new_note_1", :type => @type, :fid => @factura.id, :type => @factura.tipo
      end
      
      if params[:use_current]
        redirect_to :action => "new_note_2", :type => @type, :fid => @factura.id, :nid => @curr
      end
      
      if params[:use_from_list]
        nid = params[:nid].to_i
        
        if @numbers.include? nid
          redirect_to :action => "new_note_2", :type => @type, :fid => @factura.id, :nid => nid
        end
      end
    end
  end
  
  
  def new_note_2
    get_facturation_document_type_for_notes
    empresa = @factura.empresa
    
    @number = params[:nid].to_i
    
    unless (NoteNumber.available_for_new?(@number, @type, empresa))
      redirect_to :action => "list"
    end
    
    # FIXME detect if Factura is available for new note
    
    # Everything seems to be fine! Keep on.
    
    @form = Fionna.new "new_note_2"
    
    # ODT amounts
    @odt_amounts = Hash.new
    
    @factura.of.each do |o|
      @odt_amounts[o.id.to_s] = {
        :factura => o.monto_activo,
        :value   => "%0.2f" % o.monto_activo,
        :ignore  => false,
        :valid   => true
      }
    end
    
    if request.post?
      @form.load_values params
      
      # Details
      @details = multirow_load("note_detalle", :descripcion, :cantidad, :valor_unitario)
      
      all_fine = true
      
      if params[:ok]
        monto = 0.00
        
        # The details, are they valid?
        # We don't allow more detail rows than the Factura
        fr = @factura.details.size
        
        if @details.size > fr
          details_valid = false
          @wrong_size   = true
        else
          details_valid = multirow_validate(@details)
          
          if details_valid
            @details.each do |d|
              monto += (d.cantidad.to_f * d.valor_unitario.to_f)
            end
            
            monto = monto.round2
          end
        end
        
        # The ODT amounts, are they valid?
        odt_amounts_valid = true
        f                 = Fionna.new("new_note_2_odt_amount")
        
        @factura.of.each do |o|
          i = o.id.to_s
          if params[:odt][i].nil?
            @odt_amounts[i][:value]  = ""
            @odt_amounts[i][:valid]  = false
            @odt_amounts[i][:ignore] = false
            odt_amounts_valid        = false
          else
            m                       = params[:odt][i]
            f.monto                 = m
            @odt_amounts[i][:value] = m
            
            if params[:ignore].nil? || params[:ignore][i].nil?
              @odt_amounts[i][:ignore] = false
            else
              @odt_amounts[i][:ignore] = true
            end
            
            if f.valid?
              if m.to_f > @odt_amounts[i][:factura]
                invalid = true
              else
               invalid = false
             end
            else
              invalid = true
            end
            
            if invalid
              @odt_amounts[i][:valid] = false
              odt_amounts_valid       = false
            end
          end
        end
        
        if @form.valid?
          # Calculate if the amount we are invoicing is bigger than the
          # Factura's amount
          if monto > @factura.monto
            @monto = monto
            @wrong_amount = true
            all_fine = false
          end
        else
          all_fine = false
        end
        
        # Yay!
        if all_fine && details_valid && odt_amounts_valid
          values = @form.get_values
          
          n = NotaDeCredito.new
          
          values['fecha_emision'] = @form.process_textdate :fecha_emision
          
          values.delete 'razon_social'
          values.delete 'descripcion'
          values.delete 'cantidad'
          values.delete 'valor_unitario'
          values.delete 'one_descripcion'
          values.delete 'one_cantidad'
          values.delete 'one_valor_unitario'
          values.delete 'monto_odt'
          
          n.update_attributes values
          
          n.numero                   = @number
          n.tipo                     = @type
          n.empresa                  = empresa
          n.factura_id               = @factura.id
          n.account_id               = @factura.account_id
          n.razon_social             = @factura.razon_social
          n.ruc                      = @factura.ruc
          n.factura_direccion_fiscal = @factura.direccion_fiscal
          n.anulada                  = false
          n.en_blanco                = false
          n.cobrada                  = false
          n.confirmada               = false
          n.cargo_cobranza           = false
          n.modalidad_pago           = ''
          n.monto                    = monto
          n.moneda                   = @factura.moneda
          n.save
          
          NoteNumber.get_next(@type, empresa)
          
          # Details!
          @details.each do |d|
            nd = NotaDetalle.new({
              :nota_de_credito_id => n.id,
              :descripcion        => d.descripcion,
              :cantidad           => d.cantidad,
              :valor_unitario     => d.valor_unitario
            })
            nd.save
          end
          
          # Save the credited OF amounts
          @factura.of.each do |o|
            i = o.id.to_s
            o.monto_credito     = @odt_amounts[i][:value]
            o.ignorar_descuento = @odt_amounts[i][:ignore]
            o.save
          end
          
          if @factura.inmutable?
            @factura.make_mutable
            was_inmutable = true
          else
            was_inmutable = false
          end
          
          @factura.con_nota_de_credito = true
          @factura.save
          @factura.make_inmutable if was_inmutable
          
          redirect_to :action => "show", :nid => n.id
        end
      end
    else
      # GET!
      
      # We prefill the details with the ones of the Factura
      @details = []
      
      @factura.details.each do |d|
        f = Fionna.new("factura_detalle")
        f.descripcion    = d.descripcion
        f.cantidad       = d.cantidad.to_s
        f.valor_unitario = "%02.f" % d.valor_unitario
        
        @details << f
      end
      
      @form.load_values @factura.attributes
      @form.descripcion     = ""#@ofs.first.descripcion
      @form.fecha_emision   = @factura.fecha_emision.strftime("%d/%m/%y") unless @factura.fecha_emision.nil?
    end
  end
  
  
  def edit_note
    @form    = Fionna.new "edit_factura"
    
    @details = []
    @factura.details.each do |d|
      fd = Fionna.new("factura_detalle")
      fd.descripcion    = d.descripcion
      fd.cantidad       = d.cantidad
      fd.valor_unitario = d.valor_unitario
      @details << fd
    end
    
    if @factura.anulada? || @factura.en_blanco?
      redirect_to :action => "facturas"
    end
    
    if request.post?
      @form.load_values params
      
      # Details
      @details = multirow_load("factura_detalle_edit", :descripcion)
      
      if params[:s] || params[:c]
        # Now, the details, are they valid?
        details_valid = multirow_validate(@details)
        
        if @form.valid? && details_valid
          values  = @form.get_values
          
          values['fecha_emision'] = @form.process_textdate :fecha_emision
          
          @factura.completa = false if params[:c]
          
          values.delete "descripcion"
          values.delete "cantidad"
          values.delete "valor_unitario"
          
          @factura.update_attributes values
          @factura.save
          
          # Update the details.
          @details.each_with_index do |d, i|
            @factura.details[i].descripcion = d.descripcion
            @factura.details[i].save
          end
          
          if params[:c]
            redirect_to :action => "new_factura_1", :fid => @factura.id, :type => @type
          else
            redirect_to :action => "show_factura", :fid => @factura.id, :type => @type, :from => "f"
          end
        end
      end
    else
      @form.load_values @factura.attributes
      
      @form.fecha_emision   = @factura.fecha_emision.strftime "%d/%m/%y" unless @factura.fecha_emision.nil?
    end
  end
  
  
  def show_note
    get_comes_from
    
    @of               = @factura.of
    @fechas_probables = @factura.fechas_probables
    
    if @factura.account.nil?
      @contacto = nil
    else
      @contacto = @factura.account.contacto_cobranza || ContactoCobranza.new({ :account_id => @factura.account.id })
    end
    
    unless @factura.cobrada?
      @form  = Fionna.new "show_factura_a"
      @formb = Fionna.new "show_factura_b"
      
      # Form A
      if request.post? && params[:a]
        @form.load_values params
        
        if @form.valid?
          if @form.fecha_recepcion == ""
            fecha_recepcion = nil
          else
            fecha_recepcion = @form.process_textdate :fecha_recepcion
          end
          
          old_fecha_recepcion = @factura.fecha_recepcion
          
          @factura.fecha_recepcion = fecha_recepcion
          @factura.confirmada      = @form.confirmada
          @factura.modalidad_pago  = @form.modalidad_pago
          @factura.save
          
          @factura.reload
          
          if old_fecha_recepcion.nil? || old_fecha_recepcion.strftime("%y%m%d") != fecha_recepcion.strftime("%y%m%d")
            fp = FechaProbable.new({
              :factura_id    => @factura.id,
              :fecha         => @factura.proposed_charge_date,
              :observaciones => "Definida por Fecha de Recepcion"
            })
            fp.save
          end
          
          redirect_to :action => "show_factura", :fid => @factura.id, :from => @params[:from]
        end
      else # GET Form A
        if @factura.fecha_recepcion.nil?
          fecha_recepcion = ""
        else
          fecha_recepcion = @factura.fecha_recepcion.strftime "%d/%m/%y"
        end
        
        @form.fecha_recepcion = fecha_recepcion
        @form.confirmada      = @factura.confirmada
        @form.modalidad_pago  = @factura.modalidad_pago
      end
      
      # Form B
      
      # Form C
      unless @factura.fecha_recepcion.nil?
        if request.post? && params[:b]
          @formb.load_values params
          
          if @formb.valid?
            if @formb.fecha_probable == ""
              fecha_probable = nil
            else
              fecha_probable = @formb.process_textdate :fecha_probable
            end
            
            fp = FechaProbable.new({
              :factura_id    => @factura.id,
              :fecha         => fecha_probable,
              :observaciones => @formb.observaciones
            })
            fp.save
            
            redirect_to :action => "show_factura", :fid => @factura.id, :from => @params[:from]
          end
        else # GET Form C
          fp = @factura.current_fecha_probable
          
          if fp.nil?
            @formb.fecha_probable = ""
            @formb.observaciones  = ""
          else
            if fp.fecha
              @formb.fecha_probable = fp.fecha.strftime "%d/%m/%y"
            else
              @formb.fecha_probable = nil
            end
            @formb.observaciones  = fp.observaciones
          end
        end
      end
      
      # Form D
      if @contacto
        if validate_billing_contact_form
          redirect_to :action => "show_factura", :fid => @factura.id
        end
      end
    end
  end
  
  
  def show
  end
  
  
  def edit
    if @note.anulada? || @note.en_blanco?
      redirect_to :action => "list"
    end
    
    @form = Fionna.new "edit_note"
    
    @details = []
    @note.details.each do |d|
      fd = Fionna.new("factura_detalle")
      fd.descripcion    = d.descripcion
      fd.cantidad       = d.cantidad
      fd.valor_unitario = d.valor_unitario
      @details << fd
    end
    
    if request.post?
      @form.load_values params
      
      # Details
      @details = multirow_load("note_detalle_edit", :descripcion)
      
      if params[:ok]
        # Now, the details, are they valid?
        details_valid = multirow_validate(@details)
        
        if @form.valid? && details_valid
          values  = @form.get_values
          
          values['fecha_emision'] = @form.process_textdate :fecha_emision
          
          values.delete "descripcion"
          values.delete "cantidad"
          values.delete "valor_unitario"
          
          @note.update_attributes values
          @note.save
          
          # Update the details.
          @details.each_with_index do |d, i|
            @note.details[i].descripcion = d.descripcion
            @note.details[i].save
          end
          
          redirect_to :action => "show", :nid => @note.id
        end
      end
    else
      @form.load_values @note.attributes
      
      @form.fecha_emision   = @note.fecha_emision.strftime "%d/%m/%y" unless @note.fecha_emision.nil?
    end
  end
  
  
  def void
    @form = Fionna.new "void_nota"
    
    if request.post?
      @form.load_values params
      @form.empresa = @note.empresa.to_s
      
      if @form.valid?
        @note.anulada = true
        @note.save
        
        # Zero the credited amounts. There should be a way to keep the
        # amounts we originally credited, so it would still be posible to
        # un-void a Note.
        # This is a provisional measure. (FIXME)
        @note.factura.of.each do |o|
          o.monto_credito     = 0.00
          o.ignorar_descuento = 0
          o.save
        end
        
        @note.factura.save
        
        redirect_to :action => "show", :nid => @note.id
      end
    end
  end
  
  
end
