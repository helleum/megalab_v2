# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  helper :rbac_url

  before_filter do |c|
    User.current_user = User.find(c.session[:user]) unless c.session[:user].nil?
  end

  before_filter :login_required, :protect_with_permissions
  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_ums-megalab_session_id'

  protected

    def sanitize_search(code)
      code.gsub(/[^\w\s\.\&\'\-\+_]/,"%").upcase
    end
    
    def local_request?
      false
    end

    def action_permitted?(permission_controller, permission_action)
      return true if current_user.has_role?('Root')
      return current_user.has_permission?(permission_controller, permission_action)      
    end
    
    def protect_with_permissions
      # Set the return_to session to redirect to after login
#      session[:return_to] = '/'
      
      # protect!
      return true if logged_in? and (current_user.has_role?('Root') or current_user.has_permission?(params[:controller], params[:action]))
            
      if logged_in?
        flash.now[:error] = 'No access right for selected action'
        redirect_to "/"
      else
        redirect_to login_url
      end
      return false
    end
end
