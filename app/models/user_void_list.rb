class UserVoidList < ActiveRecord::Base
  set_table_name "user_void_list"
  belongs_to :users
end
