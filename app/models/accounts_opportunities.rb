class AccountsOpportunities < ActiveRecord::Base
  set_table_name "accounts_opportunities"
  
  belongs_to :opportunity
  belongs_to :account
end
