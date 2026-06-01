class Tracker < ApplicationRecord
 belongs_to :store

 validates :art_num, presence: true
 validates :art_name, presence: true
end
