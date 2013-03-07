class Group < ActiveRecord::Base

  # groups are arranged in a tree
  acts_as_tree :order => 'title'
  # groups have a n:m relation to user
  has_and_belongs_to_many :users, :uniq => true
  # groups have a n:m relation to groups
  has_and_belongs_to_many :roles, :uniq => true
  # we want to protect the parent and user attribute from bulk assigning
  attr_protected :parent, :users, :roles

  validates_format_of     :title, 
                          :with => %r{^[\w \$\^\-\.#\*\+&'"]*$}, 
                          :message => 'must not contain invalid characters.'
  validates_length_of     :title, 
                          :in => 2..100, :allow_nil => true,
                          :too_long => 'must have less than 100 characters.', 
                          :too_short => 'must have more than two characters.',
                          :allow_nil => false
  # We want to validate a group's title pretty thoroughly.
  validates_uniqueness_of :title, 
                          :message => 'is the name of an already existing group.'

  before_destroy :dont_destroy_default
  
  def systemgroups?
    return true if title.downcase == "system" or title.downcase == "default"
    return false
  end

  def self.defaultgroup
    default = find_by_title("default")  
    return default.id
  end
  
  def self.filtered_list
    find(:all, :conditions => ["title != \"system\" AND title != \"default\""], :order => "title")
  end
  
  # This method returns the whole inheritance tree upwards, i.e. this group
  # and all parents as a list.
  def ancestors_and_self
    result = [self]
  
    if parent != nil
      result << parent.ancestors_and_self
    end
  
    return result.flatten
  end
  
  # This method returns itself, all children and all children of its children
  # in a flat list.
  def descendants_and_self
    result = [self]
  
    for child in children
      result << child.descendants_and_self
    end
  
    return result.flatten
  end
  
  # This method returns all roles assigned to this group or any of its
  # ancessors.
  def all_roles
    result = []
  
    self.roles.each do |role|
      result << role.ancestors_and_self
    end
  
    result << parent.all_roles unless parent.nil?
  
    result.flatten!
    result.uniq!
  
    return result
  end
  
  # This method returns all users that have been assigned to this role. It
  # will all users directly assigned to this group and all users assigned to
  # children of this group.
  def all_users
    result = []
  
    self.descendants_and_self.each { |group| result << group.users }
  
    result.flatten!
    result.uniq!
  
    return result
  end

  protected
  
    def dont_destroy_default
      raise "Deleting Default groups is not allowed" if systemgroups? or title.downcase == "administrator"
    end

end
