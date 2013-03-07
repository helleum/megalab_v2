# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  layout "login"
  
  skip_filter :protect_with_permissions, :login_required
  filter_parameter_logging :password

  # render new.rhtml
  def new
  end

  def create
    unless params[:login].blank? or params[:password].blank?
      self.current_user = User.authenticate(params[:login], params[:password])
      login_name = self.current_user.login_name if logged_in?
      if logged_in? and self.current_user.groups.empty?
        log_off
        flash[:error] = "User (#{login_name}) can't be login due to User/Group error. <br />Please contact system administrator for help."
        redirect_back_or_default('/login')
      elsif logged_in? and not self.current_user.permitted?
        log_off
        flash[:error] = "User (#{login_name}) is not permitted to login. <br />Please contact system administrator for help."
        redirect_back_or_default('/login')
      elsif logged_in? and not self.current_user.active?
        log_off
        flash[:error] = "User (#{login_name}) has been disabled. <br />Please contact system administrator for help."
        redirect_back_or_default('/login')
      elsif logged_in? and self.current_user.active?
        if params[:remember_me] == "1"
          self.current_user.remember_me
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        end
        flash.now[:notice] = "Logged in successfully"
        redirect_back_or_default('/')
      else
        flash.now[:error] = "Username/Password error."
        render :action => 'new'
      end
    else
      flash.now[:error] = "Username/Password missing."
      render :action => 'new'
    end
  end

  def destroy
    log_off
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/login')
  end

  protected
  
    def log_off
      self.current_user.forget_me if logged_in?
      cookies.delete :auth_token
      reset_session
    end
end
