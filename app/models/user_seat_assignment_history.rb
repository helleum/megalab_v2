class UserSeatAssignmentHistory < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"

  belongs_to :seat
  belongs_to :user  

  cattr_reader :per_page
  @@per_page = SystemParameter.pages

  ACTION_STATE = {
    "Assign" => "1",
    "Cancel" => "2"
  }.freeze  
  
  def action?
    ACTION_STATE.index(self.action) rescue nil
  end
  
  def self.action_select
    ACTION_STATE.sort {|a,b| a[1]<=>b[1]}
  end
  
end
