class HelpRequest < ActiveRecord::Base
  apply_simple_captcha

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"

  belongs_to :seat
  belongs_to :equipment
  has_many :help_request_monitoring_histories 

  validates_presence_of :request_remark, :hardware_address
  validates_presence_of :closing_summary, :on => :update  

  cattr_reader :per_page
  @@per_page = SystemParameter.pages

  STATUS_STATE = {
    "Open" => "1",
    "Reviewing" => "2",
    "Accepted" => "3",
    "Closed" => "4"
  }.freeze
    
  def status?
    STATUS_STATE.index(self.status) rescue nil
  end

  def mark_reviewed
    self.update_attribute('status', STATUS_STATE.fetch('Reviewing'))
  end

  def open?
    status == STATUS_STATE.fetch('Open')
  end

  def reviewing?
    status == STATUS_STATE.fetch('Reviewing')
  end

  def accepted?
    status == STATUS_STATE.fetch('Accepted')
  end

  def closed?
    status == STATUS_STATE.fetch('Closed')
  end

  def release_request
    mark_reviewed   
  end

  def accept_request
    self.update_attribute('status', STATUS_STATE.fetch('Accepted'))
  end

  def self.status_select
    STATUS_STATE.sort {|a,b| a[1]<=>b[1]}
  end

end
