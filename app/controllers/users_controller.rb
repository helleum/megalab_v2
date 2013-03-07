class UsersController < ApplicationController
  layout 'popup', :except => :index

  # Be sure to include AuthenticationSystem in Application Controller instead
#  include AuthenticatedSystem

  #Filter method to enforce a login requirement
#  before_filter :login_required
  before_filter :protect_root, :only => [ :show, :edit ]
  
  def index
    @can_create = action_permitted?(params[:controller], 'new')
    
    query = ""
    query += [" and login_name LIKE ", "'%" + sanitize_search(params[:login_name]) + "%'"].to_s unless params[:login_name].blank?
    query += [" and full_name LIKE ", "'%" + sanitize_search(params[:full_name]) + "%'"].to_s unless params[:full_name].blank?
    query += " and nature =  \"#{sanitize_search(params[:nature])}\"" unless params[:nature].blank?
    query += " and status =  \"#{sanitize_search(params[:status])}\"" unless params[:status].blank?
    query += " and ml_access_status =  \"#{sanitize_search(params[:ml_status])}\"" unless params[:ml_status].blank?
    if not params[:date_from].blank? and not params[:date_to].blank?
      query += " and verification_time BETWEEN \"#{sanitize_search(params[:date_from])}\" AND \"#{sanitize_search(params[:date_to])}\""
    elsif not params[:date_from].blank?
      query += [" and verification_time LIKE ", "'%" + sanitize_search(params[:date_from]) + "%'"].to_s
    end  

    if current_user.has_role?("Root")
      user_check = "1=1"
    else
      user_check = "login_name != 'root' AND login_name != 'administrator'"
    end

    @sort = params[:sort] || 'login_name'
    @users = UserListing.paginate :page => params[:page], :conditions => user_check + query, :order => @sort
    render :layout => 'application'
  end

  # GET /users/1
  def show
  end

  def change_access
    @user = User.find(params[:id])
    if request.post?
      @user_access_history = @user.user_ml_access_control_histories.build(params[:user_access_history])
      # This assumes action states for Access History matches access states for Seat. If not then this will NOT work properly.
      @user_access_history.action = UserMlAccessControlHistory::ACTION_STATE.fetch(@user.toggle_access_view)
      if @user_access_history.save
        @user.toggle_access
        flash[:notice] = 'User access control status was successfully updated.'
        redirect_to :action => 'show', :id => @user
      else
        render :action => 'change_access'
      end
    end   
  end
  
  # GET /users/access_history/1
  def access_history
    @user = User.find(params[:id])
  end

  # GET /users/1;edit
  def edit
  end
  
  # PUT /users/1
  def update
    @user = User.find(params[:id])
    #
    @user_copy = User.find(params[:id])
    
#    if @user.verify? and (params[:user][:status] != User::STATUS_STATE.fetch('Pending Verification'))
#      params[:user][:verification_time] = nil
#      logger.info "Verified? - #{@user.verify?}, params - #{params[:user][:status]}, Status - #{User::STATUS_STATE.fetch('Pending Verification')}, Verified!"
#    elsif not @user.verify? and (params[:user][:status] == User::STATUS_STATE.fetch('Pending Verification'))
#      params[:user][:verification_time] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
#      logger.info "Verified? - #{@user.verify?}, params - #{params[:user][:status]}, Verification Time - #{params[:user][:verification_time]}, Pending Verify!"
#    end
    
    unless @user.superadmin?
      # get an array of groups and set the group associations
      params[:user][:groups] = [] if params[:user][:groups] == [""]
  
      # Keep the default group for Homepage access
      params[:user][:groups] << Group.defaultgroup
  
      groups = params[:user][:groups].collect { |i| Group.find(i) }
      @user.groups = groups
    end

    if @user.update_attributes(params[:user])
      # Check when status is Pending Verification & update verification_time or blank it as needed
      if @user_copy.verify? and (params[:user][:status] != User::STATUS_STATE.fetch('Pending Verification'))
        @user.update_attribute('verification_time', nil)
#        logger.info "Verified? - #{@user.verify?}, params - #{params[:user][:status]}, Status - #{User::STATUS_STATE.fetch('Pending Verification')}, Verified!"
      elsif not @user_copy.verify? and (params[:user][:status] == User::STATUS_STATE.fetch('Pending Verification'))
        @user.update_attribute('verification_time', Time.now)
#        logger.info "Verified? - #{@user.verify?}, params - #{params[:user][:status]}, Status - #{User::STATUS_STATE.fetch('Pending Verification')}, Pending Verify!"
      end
      flash[:notice] = 'User was successfully updated.'
      redirect_to user_url(@user)
    else
      render :action => "edit"
    end
  end

  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    @user.verification_time =  Time.now if @user.verify?
    # assign properties to user
    if @user.save
      # set the user's groups to the groups from the parameters 
      params[:user][:groups] = [] if params[:user][:groups] == [""]

      # Add in the default group for Homepage access
      params[:user][:groups] << Group.defaultgroup

      @user.groups = params[:user][:groups].collect { |i| Group.find(i) }


      # the above should be successful if we reach here; otherwise we 
      # have an exception and reach the rescue block below
      flash[:success] = 'User was created successfully.'
      redirect_to users_url
    else
      render :action => 'new'
    end
  end

  protected

    def protect_root
      @user = User.find(params[:id])
      unless current_user.has_role?('Root')
        redirect_to users_url if @user.login_name == 'root'
      end
    end
end