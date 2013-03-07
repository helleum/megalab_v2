=begin
  support function required by Permission model.
  This method was taken from:
  dev.rubyonrails.com/file/trunk/activesupport/lib/active_support/core_ext/object_and_class.rb
  Removed the condition for finding '::' so that the sub directory classes would work
=end
#def Object.subclasses_of(*superclasses)  
#  subclasses = []
#  ObjectSpace.each_object(Class) { |k|
#    next if (k.ancestors & superclasses).empty? || superclasses.include?(k) || subclasses.include?(k)  
#    subclasses << k
#  }  
#  subclasses
#end

=begin
  this class loads & examines all controllers, and produces data structures
  telling us what public methods they contain; useful for sitemap generation
  and ACL administration.

  TODO: test. Test with controllers in subdirectories.
=end
class Introspector

=begin
  Finds and loads all controllers in the application. Likely to be expensive; 
  use with restraint.
=end
  def self.load_all_controllers
    require 'find'
    # will this find controllers in subfolders? It's advertised as doing so
    Find.find( RAILS_ROOT + '/app/controllers' ) do |file_name|
      if File.basename(file_name)[0] == ?. # what's this idiom? : ?. 
        Find.prune
      else
        if /_controller.rb$/ =~ file_name
          load file_name 
        end
      end
    end 
  end

=begin
  Find the actions in each loaded controller, resulting in an array of 
  strings named like 'foo/bar' representing the controller/action
=end
  def self.find_loaded_controller_actions
    all_actions = Object.subclasses_of(ApplicationController)
    all_actions.collect! { |controller|
      # TODO : public_only logic fork to be added here ...
      methods = controller.public_instance_methods - controller.hidden_actions
      methods.collect { |method_name|
        #ignore methods ending with a ? and the 'l' method
        if /\?$/ =~ method_name || "l" == method_name
          nil
        else
#          controller.name.gsub( /Controller$/, '' ).downcase.gsub(/::/, '/') + '/' + method_name
          controller.name.gsub( /Controller$/, '' ).underscore.gsub(/::/, '/') + ',' + method_name
        end
      }
    }.flatten!.compact!

    all_actions
  end

  def self.find_all_controller_actions
    self.load_all_controllers
    self.find_loaded_controller_actions
  end

=begin
  TODO: order :actions alphabetically

  expects an array of strings like that output by 
  Introspector.find_loaded_controller_actions

  returns an array of hashes containing the :name of each controller, 
  as well as a list of its :actions; ie,
  [ 
    { :name => 'foo', :actions => [ 'index', 'list' ... ] }, 
    { etc... } 
  ]
=end 
  def self.order_action_list_by_controller(action_list)
    ordered_list = []
    action_list.each{ |actionpath|
      splitpath = actionpath.split('/')
      controllername, actionname = splitpath.first, splitpath.last
      if item = ordered_list.select{ |i| i[:name] == controllername }.first
        item[:actions] << actionname
      else
        ordered_list << { 
          :name => controllername, 
          :actions => [actionname]
        }
      end
    }
    ordered_list
  end 

end