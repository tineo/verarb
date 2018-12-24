class TipoDeCambioController < ApplicationController
  before_filter :set_tab_admin
  before_filter :check_access
  
  def list
    @fdate = Fionna.new "tc_admin_date"
    
    if params[:month]
      @fdate.load_values params
    else
      @fdate.month = Time.now.month
      @fdate.year  = Time.now.year
    end
    
    @month  = @fdate.month.to_i
    @year   = @fdate.year.to_i
    @errors = {}
    
    @tcs = TipoDeCambio.get_for_date @month, @year
    
    
    if request.post?
      m = params[:tcm].to_i
      y = params[:tcy].to_i
      d = params[:tc]
      
      redirect_to :action => "list" unless d.class.to_s == "HashWithIndifferentAccess"
      
      d.each do |day, v|
        next if day == 0
        
        day = day.to_i
        
        @f = Fionna.new "tc_admin_cambio"
        @f.cambio = v
        
        @tcs[day] = v
        
        if @f.valid?
          TipoDeCambio.update_or_create(y, m, day, v)
        else
          @errors[day] = @f.e :cambio
        end
      end
    end
  end
end

