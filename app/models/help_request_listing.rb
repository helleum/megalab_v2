class HelpRequestListing < ActiveRecord::Base

  defaults :status => nil
  
  cattr_reader :per_page
  @@per_page = SystemParameter.pages

end
