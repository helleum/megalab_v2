class EquipmentSeatAssignmentHistory < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"

  belongs_to :seat
  belongs_to :equipment

  ACTION_STATE = {
    "Assign" => "1",
    "Remove" => "2"
  }.freeze

  def action?
    ACTION_STATE.index(self.action) rescue nil
  end

end
