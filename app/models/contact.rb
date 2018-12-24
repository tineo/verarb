class Contact < ActiveRecord::Base
  has_and_belongs_to_many :accounts
  has_and_belongs_to_many :opportunities, :join_table => "opportunities_contacts"
  
  def full_name
    if self.first_name.nil? || self.last_name.nil?
      return "(Sin nombre)"
    else
      return self.first_name + " " + self.last_name
    end
  end
end
