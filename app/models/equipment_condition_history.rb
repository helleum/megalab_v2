class EquipmentConditionHistory < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"

  belongs_to :equipment

  validates_presence_of :action_remark

  ACTION_STATE = {
    "Functional" => "1",
    "Out of order" => "2"
  }.freeze

  def action?
    ACTION_STATE.index(self.action) rescue nil
  end
  
end
