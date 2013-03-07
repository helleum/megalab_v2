require 'digest/sha1'
class User < ActiveRecord::Base

  # Userstamp
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"

  has_many :user_ml_access_control_histories
  
  # users have a n:m relation to group
  has_and_belongs_to_many :groups, :uniq => true

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  # Userstamp
  cattr_accessor :current_user

  enforce_column_limits

  validates_presence_of     :login_name
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login_name, :minimum => 3
  validates_uniqueness_of   :login_name, :case_sensitive => false
  validates_uniqueness_of   :mycard_no,   :if => Proc.new { |user| !user.mycard_no.blank? }
  validates_uniqueness_of   :passport_no, :if => Proc.new { |user| !user.passport_no.blank? }
  validates_uniqueness_of   :idcard_no1,  :if => Proc.new { |user| !user.idcard_no1.blank? }
  validates_uniqueness_of   :idcard_no2,  :if => Proc.new { |user| !user.idcard_no2.blank? }
  before_save :encrypt_password
  before_save :check_display_name
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login_name, :password, :password_confirmation, 
                  :display_name, :full_name, :mycard_no, :passport_no, :nature, :description,
                  :idcard_no1, :idcard_no2, :status, :remark

  cattr_reader :per_page
  @@per_page = 50
  
  def check_display_name
    if display_name.blank?
      self.display_name = login_name
    else
      self.display_name = display_name
    end
  end
  
  NATURE_STATE = {
    "Vendor" => "1",
    "Student" => "2",
    "Staff" => "3",
    "Other" => "4"    
  }.freeze

  STATUS_STATE = {
    "Active" => "1",
    "Inactive" => "2",
    "Pending Verification" => "3"
  }.freeze  

  ACCESS_STATE = {
    "Allow" => "1",
    "Deny" => "2"
  }.freeze  

  def allowed?
    ml_access_status == ACCESS_STATE.fetch('Allow')
  end
  
  def permitted?
    nature.to_s.include?NATURE_STATE.fetch('Vendor') or nature.to_s.include?NATURE_STATE.fetch('Staff')
  end

  def active?
    status == STATUS_STATE.fetch('Active')
  end

  def verify?
    status == STATUS_STATE.fetch('Pending Verification')
  end

  def nature?
    NATURE_STATE.index(self.nature) rescue nil
  end

  def status?
    STATUS_STATE.index(self.status) rescue nil
  end

  def access?
    ACCESS_STATE.index(self.ml_access_status) rescue nil
  end

  def self.nature_select
    NATURE_STATE.sort {|a,b| a[1]<=>b[1]}
  end

  def self.status_select
    STATUS_STATE.sort {|a,b| a[1]<=>b[1]}
  end

  def self.access_select
    ACCESS_STATE.sort {|a,b| a[1]<=>b[1]}
  end

  def access_allowed
    self.update_attribute('ml_access_status', ACCESS_STATE.fetch('Allow'))
  end

  def access_denied
    self.update_attribute('ml_access_status', ACCESS_STATE.fetch('Deny'))
  end
  
  def toggle_access
    allowed? ? access_denied : access_allowed
  end

  def toggle_access_view
    allowed? ? 'Deny' : 'Allow'
  end
  
  # This method returns all roles assigned to the given user - including
  # the ones he gets by being assigned a child role (i.e. the parents)
  # and the one he gets through his groups (inheritance is also considered)
  # here.
  def all_roles
    result = Array.new
  
#    for role in self.roles
#      result << role.ancestors_and_self
#    end
  
    for group in self.groups
      result << group.all_roles
    end
  
    result.flatten!
    result.uniq!
  
    return result
  end
  
  # This method returns all groups assigned to the given user - including
  # the ones he gets by being assigned through group inheritance.
  def all_groups
    result = Array.new
  
    for group in self.groups
      result << group.ancestors_and_self
    end
  
    result.flatten!
    result.uniq!
  
    return result
  end
  
  # This method returns true if the user is assigned the role with one of the
  # role titles given as parameters. False otherwise.
  def has_role?(*role_titles)
    obj = all_roles.detect do |role| 
            role_titles.include?(role.title)
          end
    
    return !obj.nil?
  end
  
  # This method returns a list of all the StaticPermission entities that
  # have been assigned to this user through his roles.
  def all_permissions
    permissions = Array.new
  
    all_roles.each do |role|
      permissions.concat(role.permissions)
    end
  
    return permissions
  end

  # This method returns true if the user is granted the permission with one
  # of the given permission titles.
  def has_permission?(permission_controller, permission_action)
    all_roles.detect do |role| 
      role.permissions.detect do |permission|
        return true if permission_controller.to_s.casecmp(permission.controller_name).zero? and permission_action.to_s.casecmp(permission.action_name).zero?
      end
    end
    return false
  end

  # Check if the user is among the built in super admin accounts
  def superadmin?
    return true if login_name == "root" or login_name == "administrator"
    return false
  end

  # Display the current user group after removing default group.
  def showgroup
    group = groups.map(&:id)
    group.delete(Group.defaultgroup)
    return "None" if group.empty?
    Group.find(group.to_s).title 
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login_name(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{login_name}--#{remember_token_expires_at}")
#    save(false)
    self.class.execute_without_timestamps { save(false) }
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
#    save(false)
    self.class.execute_without_timestamps { save(false) }
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login_name}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end

    # This method allows to execute a block while deactivating timestamp
    # updating.
    def self.execute_without_timestamps
      old_state = ActiveRecord::Base.record_timestamps
      ActiveRecord::Base.record_timestamps = false

      yield

      ActiveRecord::Base.record_timestamps = old_state
    end
    
end
