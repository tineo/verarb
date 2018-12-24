class OpportunitiesController < ApplicationController
  before_filter :set_tab
  
  def panel
    @form = Fionna.new "opportunities_panel"
    @opps = []
    
    @order = get_order_field_for "opportunities"
    order  = @order[:query]
    
    if order == "DEFAULT"
      order = "opportunities.date_entered DESC"
    end
    
    reset_filter("opportunities") if params[:reset_filters]
    set_filter("opportunities", params) if params[:q]
    
    @form.load_values get_filter("opportunities")
    
    if @form.valid?
      conditions = ''
      
      unless is_admin?
        conditions = "AND accounts.assigned_user_id='#{session[:user][:id]}' "
      end
      
      unless @form.client == ""
        a = Account.search(@form.client).id
        conditions += " AND accounts.id='#{a}'"
      end
      
      @opps = Opportunity.find_by_sql "
        SELECT DISTINCT opportunities.*
          FROM opportunities,
               accounts,
               accounts_opportunities
         WHERE accounts_opportunities.opportunity_id=opportunities.id
           AND accounts_opportunities.account_id=accounts.id
           AND accounts_opportunities.deleted='0'
           AND opportunities.deleted='0'
           AND accounts.deleted='0'
           #{conditions}
      ORDER BY #{order}"
      
      # Sort by Project/ODT IDs
      if ["proyecto", "odt"].include? @order[:field]
        @opps = @opps.sort_by { |o|
          if o.project.nil?
            0
          else
            if @order[:field] == "proyecto"
              o.project.id
            else
              o.project.orden_id
            end
          end
        }.reverse
      end
      
      # Sort by Project/ODT creation dates
      if ["creacion_pro", "creacion_odt"].include? @order[:field]
        @opps = @opps.sort_by { |o|
          if o.project.nil?
            10.years.ago
          else
            if @order[:field] == "creacion_pro"
              date = o.project.fecha_creacion_proyecto
            else
              date = o.project.fecha_creacion_odt
            end
            
            if date.nil?
              10.years.ago
            else
              date
            end
          end
        }.reverse
      end
    end
  end
  
  
  def auto_complete_for_account_name
    super_auto_complete_for_account_name
  end
  
  
  def show
    @opp     = Opportunity.find params[:id]
    @account = @opp.accounts.first
  end
  
  
  def set_tab
    set_current_tab "opportunities"
  end
  
  
  def set_sort_field
    f = params[:field]
    
    if f == "proyecto"
      query = "opportunities.id"
    
    elsif f == "odt"
      query = "opportunities.id"
    
    elsif f == "propuesta"
      query = "opportunities.name ASC"
    
    elsif f == "cliente"
      query = "accounts.name ASC"
    
    elsif f == "estado"
      query = "sales_stage ASC"
    
    elsif f == "creacion_opp"
      query = "opportunities.date_entered DESC"
    
    elsif f == "creacion_pro"
      query = "opportunities.id"
    
    elsif f == "creacion_odt"
      query = "opportunities.id"
    
    else
      query = "DEFAULT"
    end
    
    set_order_field_for "opportunities", f, query
    
    redirect_to :action => "panel"
  end
  
end
