class Account < ActiveRecord::Base
  has_and_belongs_to_many :contacts, :order => "first_name, last_name"
  has_and_belongs_to_many :opportunities
  has_one :contacto_cobranza
  
  def self.search(name)
    return Account.find_by_deleted_and_name("0", name)
  end
  
  
  def self.sql_search(name)
    a = Account.find_by_deleted_and_name("0", name)
    return false unless a
    
    as = Account.find_all_by_deleted_and_sic_code("0", a.ruc)
    return false if as.empty?
    
    as = as.map do |a|
      "'#{a.id}'"
    end
    
    return "(" + as.join(", ") + ")"
  end
  
  
  def ruc
    return self.sic_code
  end
  
  
  def related_accounts
    return Account.find_by_sql("SELECT accounts.* FROM accounts, related_accounts WHERE account_id='#{self.id}' AND accounts.id=related_accounts.related_id")
  end
  
  
  def contacto_cobranza
    return ContactoCobranza.find_by_account_id(self.id)
  end
  
  
  def self.list_with_relations
    return Account.find_by_sql("
      SELECT DISTINCT accounts.*
        FROM accounts,
             related_accounts
       WHERE accounts.id=related_accounts.account_id
    ORDER BY accounts.name")
  end
  
  
  def self.list_blocked_or_long_billing
    return Account.find_by_sql("
      SELECT *
        FROM accounts
       WHERE (blocked='1'
          OR cobranza_larga='1')
    ORDER BY accounts.name")
  end
  
  
  def extras
    if @extras.nil?
      ae = AccountExtra.find_by_account_id(self.id)
      
      if ae.nil?
        @extras = AccountExtra.new({
          :account_id        => self.id,
          :factura_direccion => "",
          :dias_plazo        => nil
        })
      else
        @extras = ae
      end
    end
    
    return @extras
  end
  
  
end
