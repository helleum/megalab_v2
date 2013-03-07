class UserMlAccessControlHistory < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"

  belongs_to :users

  validates_presence_of :action_remark
  
  ACTION_STATE = {
    "Allow" => "1",
    "Deny" => "2"
  }.freeze

  def action?
    ACTION_STATE.index(self.action) rescue nil
  end

end
