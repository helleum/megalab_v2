class UserListing < ActiveRecord::Base

  defaults :nature => nil, :status => nil, :ml_access_status => nil
  
  cattr_reader :per_page
  @@per_page = SystemParameter.pages

end
