class SeatListing < ActiveRecord::Base

  defaults :status => nil, :st_condition => nil, :duration => nil
  
  cattr_reader :per_page
  @@per_page = SystemParameter.pages

end
