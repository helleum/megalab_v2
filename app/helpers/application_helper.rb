# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def check_blank(v)
    v.blank? ? '&nbsp;' : v
  end
  
  def edit_img
    'edit.gif'
  end
  
  def delete_img
    'delete.gif'
  end  

  def show_img
    'show.gif'
  end

  def fmt_icon_title(title)
    title_ext = File.extname(title)
    title_base = File.basename(title, title_ext)    
    return title_base.titleize
  end

  # Helper to create link_to with image icon. This bypasses permissions check in link_to.
  def icon_to(source, options = {}, html_options = {}, *parameters_for_method_reference)
    link_to_original(image_tag(source.downcase, :border => 0, :align => "top", :title => fmt_icon_title(source)), options, html_options, *parameters_for_method_reference)
  end
  
  #------------------------------------------------------------------------------------
  # Navigation button helper (styles)
  #------------------------------------------------------------------------------------
  
  def style_link_to_buttons(content = nil)
    str = '<div class="buttonleft"></div><div class="buttonbg">'
    str += content.to_s 
    str += '</div><div class="buttonright"></div>'
    str
  end
  
  def fmt_datetime(date)
    date.strftime("%Y-%m-%d %I:%M%p")
  end
  
  def fmt_date(date)
    date.strftime("%Y-%m-%d")
  end

  # Creates a button_to without the form tags
  def button_to_link_original(name, options = {}, html_options = {})
    options = options.symbolize_keys.update( :only_path => false ) if options.kind_of? Hash
    url = url_for(options)
    button_to_function name, "window.location = '" + url + "'", html_options
  end
  
  # This method helps the rbac/* controller to render a ActiveRecord tree.
  # that uses "acts_as_tree". You only pass the record array with the nodes 
  # to display and optionally a block to format the node output.
  def node_tree(nodes, &block)
    
    nodes = nodes.dup
    printed_nodes = []
    
    result = "<ul>"
    
    # top level nodes first, then others
    for node in nodes
      next unless node.parent == nil
      printed_nodes << node
      result += "<li>"

      if block_given?
        result += yield node
      else
        result += node.title
      end

      children = node.children.dup
      children.delete_if { |r| not nodes.include?(r) }
      if not children.empty?
        result += node_tree_help(children, nodes, printed_nodes, &block)
      end
      
      result += "</li>"
    end
    
    # TODO: Add depth counting here to get a minimum of trees
    for node in nodes
      next if printed_nodes.include? node
      printed_nodes << node
      
      result += "<li>"

      if block_given?
        result += yield node
      else
        result += node.title
      end

      children = node.children.dup
      children.delete_if { |r| not nodes.include?(r) }

      if not children.empty?
        result += node_tree_help(children, nodes, printed_nodes, &block)
      end
      
      result += "</li>"
    end

    result += '</ul>'

    return result
  end
 
  protected
    def node_tree_help(children, nodes, printed_nodes, &block) # :nodoc:
      result = '<ul>'
      for child in children
        next if printed_nodes.include?(child)
        printed_nodes << child
      
        result += '<li>'

        if block_given?
          result += yield child
        else
          result += child.title
        end

        children2 = child.children.dup
        children2.delete_if { |r| not nodes.include?(r) }
        if not children2.empty?
          result += node_tree_help(children2, nodes, printed_nodes, &block)
        end

        result += '</li>'
      end

      result += '</ul>'
    end

    def level_count(node) # :nodoc:
      counts = [0]
      node.children.each { |n| counts <<  1 + level_count(n) }
      return counts.max
    end

end
