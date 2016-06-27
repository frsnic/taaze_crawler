class Book < ActiveRecord::Base
  paginates_per 20

  default_scope { order('rate DESC') }

end
