class Seat < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"

  belongs_to :user
  has_many :equipment_seat_assignment_histories
  has_many :seat_condition_histories
  has_many :equipment

  enforce_column_limits
  
  validates_presence_of :display_name
  validates_uniqueness_of :display_name

  cattr_reader :per_page
  @@per_page = SystemParameter.pages

  def self.generate_seat(from, to)
    seat_sql = <<SEAT_SQL
        SELECT id FROM seats WHERE id BETWEEN '#{from}' and '#{to}'
SEAT_SQL
    
   return ActiveRecord::Base.connection.select_values(seat_sql)
     rescue
      ""    
  end
  
  
  STATUS_STATE = {
    "Vacant" => "1",
    "Reserved" => "2",
    "Occupied" => "3"
  }.freeze

  CONDITION_STATE = {
    "Functional" => "1",
    "Out of order" => "2",
    "Block" => "3"    
  }.freeze

  def condition_select_stripped
    @select = CONDITION_STATE.dup
    @select.delete(condition?)
    @select.sort {|a,b| a[1]<=>b[1]}
  end
  
  def status?
    STATUS_STATE.index(self.status) rescue nil
  end
  
  def condition?
    CONDITION_STATE.index(self.condition) rescue nil
  end

  def self.status_select
    STATUS_STATE.sort {|a,b| a[1]<=>b[1]}
  end

  def self.condition_select
    CONDITION_STATE.sort {|a,b| a[1]<=>b[1]}
  end
  
end
