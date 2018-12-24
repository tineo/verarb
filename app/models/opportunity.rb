class Opportunity < ActiveRecord::Base
  has_and_belongs_to_many :contacts, :join_table => "opportunities_contacts"
  has_and_belongs_to_many :accounts, :conditions => "accounts_opportunities.deleted='0'"
  has_many :accounts_list, :class_name => "AccountsOpportunities"
  has_many :contacts_list, :class_name => "OpportunitiesContact"
  
  def self.create_guid
  # Based on SugarCRM's create_guid() function on include/utils.php
    dec_hex = sprintf("%x", Time.now.usec * 1000000).to_s
    sec_hex = sprintf("%x", Time.now.to_i).to_s
    
    dec_hex = Opportunity.ensure_length(dec_hex, 5)
    sec_hex = Opportunity.ensure_length(sec_hex, 6)
    
    guid  = ''
    guid += dec_hex
    guid += Opportunity.create_guid_section(3)
    guid += '-'
    guid += Opportunity.create_guid_section(4)
    guid += '-'
    guid += Opportunity.create_guid_section(4)
    guid += '-'
    guid += Opportunity.create_guid_section(4)
    guid += '-'
    guid += sec_hex
    guid += Opportunity.create_guid_section(6)
    
    return guid
  end
  
  
  def self.create_guid_section(size)
  # Based on SugarCRM's create_guid_section() function on include/utils.php
    r = ''
    size.times do
      r += sprintf("%x", rand(15))
    end
    
    return r
  end
  
  
  def self.ensure_length(string, length)
  # Based on SugarCRM's ensure_length() function on include/utils.php
    if string.size < length
      string = string.rjust(length, "0")
    elsif string.size > length
      string = string[0...length]
    end
    
    return string
  end
  
  
  def self.list_new
    conditions = "sales_stage NOT IN ('Closed Lost') AND NOT #{SQL_VERA_DELETED} AND with_project=0"
    
    ops = Opportunity.find :all, :conditions => conditions, :order => "date_entered DESC"
    
    return ops
  end
  
  
  def self.list_new_for(uid)
    conditions = "assigned_user_id=? AND sales_stage NOT IN ('Closed Lost') AND NOT #{SQL_VERA_DELETED} AND with_project=0"
    
    ops = Opportunity.find :all, :conditions => [conditions, uid], :order => "date_entered DESC"
    
    return ops
  end
  
  
  def amount_as_soles
    if self.currency_id == CRM_CURRENCY_SOLES
      return self.amount
    else
      return (self.amount * self.tipo_de_cambio).round2
    end
  end
  
  
  def amount_as_dollars
    if self.currency_id == CRM_CURRENCY_DOLARES
      return self.amount
    else
      return (self.amount / self.tipo_de_cambio).round2
    end
  end
  
  
  def tipo_de_cambio
    tc = TipoDeCambio.find_by_fecha self.date_entered
    
    if tc
      return tc.cambio
    else
      return 1.00
    end
  end
  
  
  def executive
    if self.assigned_user_id.nil?
      raise "La Oportunidad #{self.opportunity.id} no tiene un Ejecutivo asignado"
    end
    
    return User.find(self.assigned_user_id)
  end
  
  
  def project
    return Proyecto.find_by_opportunity_id(self.id)
  end
  
  
  def order
    p = self.proyecto
    
    if p.nil?
      return nil
    elsif p.con_orden_de_trabajo?
      return p.orden_id
    else
      return nil
    end
  end
  
  
  def set_account_to(aid)
    ao = AccountsOpportunities.find_by_opportunity_id_and_deleted self.id, '0'
    
    if ao
      ao.account_id = aid
      ao.save
    end
  end
  
end
