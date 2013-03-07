class SystemParameter < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"
  
  enforce_column_limits
  
  validates_presence_of :name, :message => "is a required field"
  validates_presence_of :value, :message => "is a required field"  

  # Check if system parameter is public editable
  def is_editable?
    is_public
  end
  
  def self.pages
    find_by_name("paginator").value.to_i
  end

  protected

    def validate
        errors.add(:value, "must be less or equals to 100") if is_string == false and value.to_i > 100
        errors.add(:value, "must be more or equals to 3") if is_string == false and value.to_i < 3
    end  
end
