class Atributo < ActiveRecord::Base
  belongs_to :category
  belongs_to :producto, :order => "orden"
end
