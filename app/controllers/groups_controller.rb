class GroupsController < ApplicationController
  layout 'popup', :except => :index

  before_filter :protect_root_group, :only => [ :show, :edit ]
  
  # GET /groups
  # GET /groups.xml
  def index
    @can_create = action_permitted?(params[:controller], 'new')
    @can_edit = action_permitted?(params[:controller], 'edit')
    @can_del = action_permitted?(params[:controller], 'destroy')
    
    if current_user.has_role?('Root')
      @groups = Group.find(:all, :order => "title")
    else
      @groups = Group.filtered_list    
    end

    respond_to do |format|
      format.html { render :layout => 'application' } # index.rhtml
      format.xml  { render :xml => @groups.to_xml }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @group.to_xml }
    end
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  # GET /groups/1;edit
  def edit
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group])

    # set parent manually
    @group.parent = Group.find(params[:group][:parent]) unless params[:group][:parent].to_s.empty?

    respond_to do |format|
      if @group.save
        # set the groups's roles to the roles from the parameters 
        params[:group][:roles] = [] if params[:group][:roles].nil?
        @group.roles = params[:group][:roles].collect { |i| Role.find(i) }
        
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to groups_url }
        format.xml  { head :created, :location => groups_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors.to_xml }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])

    # get an array of roles and set the role associations
    params[:group][:roles] = [] if params[:group][:roles].nil?
    roles = params[:group][:roles].collect { |i| Role.find(i) }
    @group.roles = roles

    # set parent manually
    if params[:group][:parent].to_s.empty?
      @group.parent = nil
    else
      @group.parent = Group.find(params[:group][:parent])
    end

    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to groups_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors.to_xml }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.xml  { head :ok }
    end
  rescue
    flash[:error] = 'An error has occured when trying to delete selected Group.'
    redirect_to groups_url
  end

  protected

    def protect_root_group
      @group = Group.find(params[:id])
      unless current_user.has_role?('Root')
        redirect_to groups_url if @group.systemgroups?
      end
    end
end
