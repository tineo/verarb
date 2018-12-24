class AccountExtra < ActiveRecord::Base
  set_table_name "accounts_extras"
  belongs_to :accounts
end
