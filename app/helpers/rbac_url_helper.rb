module RbacUrlHelper
  include ActionView::Helpers::UrlHelper
  
#  alias_method :link_to_unless_current_original, :link_to_unless_current unless method_defined?(:link_to_unless_current_original)
  alias_method :link_to_original, :link_to unless method_defined?(:link_to_original)
  # Skip alias method for button_to_link - Cant find it.. Renamed the function in app helper instead

#  def link_to_unless_current(name, options = {}, html_options = {}, *params, &block)
#
#    if options.kind_of? String
#      return link_to_unless_current_original(name, options, html_options, params)
#    else
#      return link_to_unless_current_original(name, options, html_options, params) if permission_to_link?(options)
#      return ""      
#    end
#  end
  
  def link_to(name, options = {}, html_options = {}, *params, &block)
    
    rtn = ""
    if options[:show_title]
      rtn =  name
      options.delete :show_title
    end
    
    if options.kind_of? String
      return link_to_original(name, options, html_options, params)
    else
      return link_to_original(name, options, html_options, params) if permission_to_link?(options)
      return rtn      
    end
  end
  
   def button_to_link(name, options = {}, html_options = {})
    
    rtn = ""
    if options[:show_title]
      rtn =  name
      options.delete :show_title
    end
    
    if options.kind_of? String
      return button_to_link_original(name, options, html_options)
    else
      return button_to_link_original(name, options, html_options) if permission_to_link?(options)
      return rtn      
    end
  end
  
  
  def permission_to_link? ( options = {} )

    # we need to strip leading slashes when checking authorisation, 
    # but not when actually generating the link.
    auth_options = options.dup
    auth_options[:controller] ||= params[:controller]
    auth_options[:action] ||= "index"
    
    auth_options[:controller] = auth_options[:controller].gsub(/^\//, '')

#    logger.info "Controller: #{auth_options[:controller]} | Action: #{auth_options[:action]}" unless current_user.has_role?("Root")
    
    return true if current_user.has_role?("Root") or current_user.has_permission?(auth_options[:controller], auth_options[:action])
#    return true if logged_in? and current_user.has_permission?(auth_options[:controller], auth_options[:action])
    return false
  end
  
end
