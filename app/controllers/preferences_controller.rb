class PreferencesController < ApplicationController
  layout 'popup'

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
  end

  def my_account
    @account = User.find_by_id(session[:user])
    if request.post?
      if @account.update_attributes(params[:account])
        flash[:notice] = 'My Account details was successfully updated.'
        redirect_to :controller => 'preferences'
      else
        render :action => "my_account"
      end
    end
  end  

  def paginator
    @paginator = SystemParameter.find_by_name("paginator")
    if request.post?
      if @paginator.update_attributes(params[:paginator])
        flash[:notice] = 'Paginator was successfully updated.'
        redirect_to :controller => 'preferences'
      else
        render :action => "paginator"
      end
    end    
  end

  def list
    @can_create = action_permitted?(params[:controller], 'new')
    @system_parameters = SystemParameter.paginate :page => params[:page]
  end

  def new
    @system_parameter = SystemParameter.new
  end

  def create
    @system_parameter = SystemParameter.new(params[:system_parameter])
    if @system_parameter.save
      flash[:notice] = 'New Parameter was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @system_parameter = SystemParameter.find(params[:id])
  end

  def update
    @system_parameter = SystemParameter.find(params[:id])
    if @system_parameter.update_attributes(params[:system_parameter])
      flash[:notice] = 'Parameter was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    SystemParameter.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

#  def show
#    @system_parameter = SystemParameter.find(params[:id])
#  end

end
