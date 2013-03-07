class Role < ActiveRecord::Base

  # roles are arranged in a tree
  acts_as_tree :order => 'title'
  # roles have n:m relations to groups
  has_and_belongs_to_many :groups, :uniq => true
  # roles have n:m relations to permissions
  has_and_belongs_to_many :permissions, :uniq => true
  # protect users and groups from mass assigning - we want to do those
  # manually
  attr_protected :users, :parent, :permissions

  validates_format_of     :title, 
                          :with => %r{^[\w \$\^\-\.#\*\+\,&'"]*$}, 
                          :message => 'must not contain invalid characters.'
  validates_length_of     :title, 
                          :in => 2..100, :allow_nil => true,
                          :too_long => 'must have less than 100 characters.', 
                          :too_short => 'must have more than two characters.',
                          :allow_nil => false
  # We want to validate a role's title pretty thoroughly.
  validates_uniqueness_of :title, 
                          :message => 'is the name of an already existing role.'

  before_destroy :dont_destroy_admin

  def self.filtered_list
    find(:all, :conditions => ["title != \"Root\" AND title != \"HomePage\""], :order => "title")
  end

  def systemroles?
    return true if title.downcase == 'administrator' or title.downcase == 'root' or title.downcase == 'homepage'
    return false
  end

  # This method returns the whole inheritance tree upwards, i.e. this role
  # and all parents as a list.
  def ancestors_and_self
    result = [self]
  
    if parent != nil
      result << parent.ancestors_and_self
    end
  
    result.flatten!
    result.uniq!
  
    return result
  end
  
  # This method returns itself, all children and all children of its children
  # in a flat list.
  def descendants_and_self
    result = [self]
  
    children.each { |child| result << child.descendants_and_self }
  
    result.flatten!
  
    return result
  end

  protected
  
    def dont_destroy_admin
      raise "Deleting Default Administration role is not allowed" if systemroles?
    end
end
