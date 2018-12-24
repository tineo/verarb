class Group < ActiveRecord::Base
  has_many :members, { :class_name => "GroupMember" }
end
