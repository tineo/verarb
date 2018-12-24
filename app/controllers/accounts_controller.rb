class AccountsController < ApplicationController
  def related_index
    @form = Fionna.new "related_account"
    @relations = Account.list_with_relations
    @blocked   = Account.list_blocked_or_long_billing
    
    if request.post?
      @form.cuenta = params[:account][:name]
      
      if @form.valid?
        a = Account.find_by_name @form.cuenta
        
        unless a.nil?
          redirect_to :action => "related_edit", :id => a.id
        end
      end
    end
  end
  
  
  def related_edit
    @account = Account.find params[:id]
    @form    = Fionna.new "related_account"
    
    if request.post?
      # Update the extras of this Account
      if params[:extras]
        @account.blocked        = (params[:blocked] == "1")
        @account.cobranza_larga = (params[:long] == "1")
        @account.save
        
        redirect_to :action => "related_edit", :id => @account.id
      
      else
      # Relation stuff
        @form.cuenta = params[:account][:name]
        
        if @form.valid?
          a = Account.find_by_name @form.cuenta
          
          unless a.nil?
            unless @account.related_accounts.include? a
              ra = RelatedAccount.new({
                :account_id => @account.id,
                :related_id => a.id
              })
              ra.save unless a.id == @account.id
            end
            
            redirect_to :action => "related_edit", :id => @account.id
          end
        end
      end
    end
  end
  
  
  def related_delete
    a = params[:id]
    r = params[:rid]
    
    ra = RelatedAccount.find_by_account_id_and_related_id a, r
    ra.destroy if ra
    
    redirect_to :action => "related_edit", :id => a
  end
  
  
  def auto_complete_for_account_name
    super_auto_complete_for_account_name
  end
  
  
  def accounts_extras
    @form = Fionna.new "accounts_extras"
    
    if request.post?
      @form.cuenta = params[:account][:name]
      
      if @form.valid?
        a = Account.find_by_name @form.cuenta
        
        unless a.nil?
          redirect_to :action => "accounts_extras_edit", :id => a.id
        end
      end
    end
  end
  
  
  def accounts_extras_edit
    @account = Account.find params[:id]
    @form    = Fionna.new "accounts_extras_edit"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        extras = @account.extras
        extras.update_attributes @form.get_values
        extras.save
        
        redirect_to :action => "accounts_extras_edit", :id => @account.id
      end
    else
      @form.load_values @account.extras.attributes
    end
  end
end
