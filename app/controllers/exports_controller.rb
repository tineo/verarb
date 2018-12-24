class ExportsController < ApplicationController
  def export_for_budget
    # Projects first
    @list = Proyecto.export_projects_list
    
    @list.each do |p|
      p.export_project_to_file
    end
    
    # Orders now
    @list = Proyecto.export_orders_list
    
    @list.each do |p|
      moneda = p.moneda_odt
      amount = p.monto_activo
      
      amount = 0.00 if amount.nil?
      
      if p.is_a_grio?
        g      = p.get_parent_project
        moneda = g.moneda_odt
      end
      
      s = p.id.to_s.pad(10) +
          p.orden_id.to_s.pad(10) +
          p.fecha_creacion_odt.strftime("%d/%m/%Y").pad(10) +
          (" %.2f" % amount).to_s.pad(10) +
          moneda.pad(1) +
          ""
      
      f = File.open(BUDGET_EXPORT_PATH + "O" + p.orden_id.to_s.rjust(10, "0") + ".txt", "w")
      f.print s
      f.close
      
      # Now it's associated project
      p.export_project_to_file
      
      p.orden_exportada = true
      p.save
    end
    
    render :text => "OK"
  end
  
  
  def export_guias
    render :text => "OK"
  end
  
  
  def executives_quotas_cron
    # Create new Cabeceras for the months that haven't been calculated yet
    curr   = ComisionesCabecera.calc_start_month
    finish = (Time.now - 1.month).beginning_of_month
    
    while curr <= finish
      exec_data = Proyecto.calculate_executives_quotas(curr, "0")
      
      exec_data.each do |e|
        cc = ComisionesCabecera.new({
          :fecha_origen => curr,
          :user_id      => e.user_id
        })
        cc.create
        
        if e.sold >= e.quota && e.quota != 0
          cc.pre_monto = (e.sold - e.quota)
          cc.monto     = 0.00
          cc.save
          
          e.sold_odts.each do |o|
            cd = ComisionesDetalle.new({
              :comisiones_cabecera_id => cc.id,
              :proyecto_id            => o.id
            })
            cd.save
          end
        end
      end
      
      curr = curr.next_month
    end
    
    # Now let's check the bill status of the remaining Cabeceras
    comissions = ComisionesCabecera.pending
    
    comissions.each do |c|
      complete    = true
      newest_date = 100.years.ago
      
      if c.detalles.empty?
        complete = false
      else
        c.detalles.each do |d|
          p = d.project
          
          if p.account.cobranza_larga? || p.cobrada?
            m = p.most_recent_factura_date
            
            if m > newest_date
              newest_date = m
            end
          else
            complete = false
          end
        end
      end
      
      if complete == true
        m = newest_date.next_month.beginning_of_month
        comission = c.user.cuota(m).comision
        
        c.monto = (c.pre_monto * (comission / 100.00)).round
        c.fecha_cobrada = m
        c.save
        
        #Mail.notify_executive_commission(c)
      end
    end
    
    render :text => "OK"
  end
  
  
  def insumos_cron
    proyectos = Proyecto.find_by_sql "
      SELECT *
        FROM proyectos
       WHERE con_orden_de_trabajo='1'
         AND anulado='0'
         AND insumos_checked='0'
         AND inmutable='0'"
    
    proyectos.each do |p|
      i = p.total_sispre_insumos
      m = p.monto_de_venta_as_dollars
      
      unless m == 0.00
        e = ((i * 100) / m).round
        
        if e >= Proyecto.insumos_percent
          Mail.notify_insumos_percent_exceeded(p, e)
          
          p.insumos_checked = true
          p.save
        end
      end
    end
    
    render :text => "OK"
  end
  
  
  def costo_variable_cron
    Proyecto.update_variable_costs
    render :text => "OK"
  end
  
end

