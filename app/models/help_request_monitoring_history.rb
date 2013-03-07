class HelpRequestMonitoringHistory < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"

  belongs_to :help_request

  ACTION_STATE = {
    "Open" => "1",
    "Reviewing" => "2",
    "Accept" => "3",
    "Release" => "4",
    "Close" => "5"
  }.freeze
    
  def action?
    ACTION_STATE.index(self.action) rescue nil
#    case self.action
#      when "1" then " open"
#      when "2" then " reviewing"
#      when "3" then " accepted"
#      when "4" then " released"      
#      else "close"
#    end
  end
end
