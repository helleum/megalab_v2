class EquipmentListing < ActiveRecord::Base

  defaults :eq_condition => nil
  
  cattr_reader :per_page
  @@per_page = SystemParameter.pages

end
