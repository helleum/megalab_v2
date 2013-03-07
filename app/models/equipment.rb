class Equipment < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"

  belongs_to :seat
  has_many :help_requests
  has_many :equipment_condition_histories
  has_many :equipment_seat_assignment_histories

  enforce_column_limits
  
  validates_presence_of :serial_no
  validates_uniqueness_of :asset_no, :if => Proc.new { |equipment| equipment.asset_no != '' }
  validates_uniqueness_of :hardware_address, :if => Proc.new { |equipment| equipment.hardware_address != '' }
  validates_uniqueness_of :serial_no

  cattr_reader :per_page
  @@per_page = SystemParameter.pages

  CONDITION_STATE = {
    "Functional" => "1",
    "Out of order" => "2"
  }.freeze

  def condition?
    CONDITION_STATE.index(self.condition) rescue nil
  end
  
  def functional?
    condition == CONDITION_STATE.fetch('Functional')
  end

  def condition_functional
    self.update_attribute('condition', CONDITION_STATE.fetch('Functional'))
  end

  def condition_out_of_order
    self.update_attribute('condition', CONDITION_STATE.fetch('Out of order'))
  end

  def toggle_condition
    functional? ? condition_out_of_order : condition_functional
  end

  def toggle_condition_view
    functional? ? 'Out of order' : 'Functional'
  end

  def seat_remove
    self.update_attribute('seat_id', nil)
  end

  def self.condition_select
    CONDITION_STATE.sort {|a,b| a[1]<=>b[1]}
  end
   
end
