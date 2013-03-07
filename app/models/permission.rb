class Permission < ActiveRecord::Base

  # static permissions have n:m relations to roles
  has_and_belongs_to_many :roles, :uniq => true

  cattr_reader :per_page
  @@per_page = 40
  
  # Ensure that the table has one entry for each controller/action pair
  def self.synchronize_with_controllers
    result = false
    all_actions = Introspector::find_all_controller_actions

    # Find all the 'action_path' columns currently in permissions table
    all_records = self.find(:all)
    known_actions = all_records.collect{ |p| p.controller_name + "," + p.action_name }

    # If controllers/actions exist that aren't in the db
    # then add new entries for them
    missing_from_db = all_actions - known_actions
    unless missing_from_db.empty?

      for permission in missing_from_db
        c_name, a_name = permission.split(",")
        self.new( :controller_name => c_name, :action_name => a_name ).save
      end
      result = true
    end
    
    # Clear out any entries in the table that do not
    # correspond to an existing controller/action
    bogus_db_actions = known_actions - all_actions
    unless bogus_db_actions.empty?
      # Create a mapping of path->Act instance for quick deletion lookup

      ids_to_delete = []
      for permission in bogus_db_actions
        c_name, a_name = permission.split(",")
        records_to_delete = self.find(:first, :select => "id", :conditions => ["controller_name = ? AND action_name = ?", c_name, a_name])
        ids_to_delete << records_to_delete.id
      end

      delete(ids_to_delete)
      result = true
    end
    return result
  end

  validates_presence_of   :controller_name, :action_name, 
                          :message => 'must be given.'
  validates_format_of     :controller_name, :action_name, 
                          :with => %r{^[\w \/\$\^\-\.#\*\+&'"]*$}, 
                          :message => 'must not contain invalid characters.'
  validates_length_of     :controller_name, :action_name,
                          :in => 2..100, :allow_nil => true,
                          :too_long => 'must have less than 100 characters.', 
                          :too_short => 'must have more than two characters.'

  protected
 
    def validate
      if Permission.find(:first, :conditions => ["controller_name = ? AND action_name = ?", controller_name, action_name])
        errors.add_to_base("Permission already exists!")
      end
    end
end
