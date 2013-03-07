class RolesController < ApplicationController
  layout 'popup', :except => :index
  
  # GET /roles
  # GET /roles.xml
  def index
    @roles = Role.find(:all, :order => "title")

    respond_to do |format|
      format.html { render :layout => 'application' } # index.rhtml
      format.xml  { render :xml => @roles.to_xml }
    end
  end

  # GET /roles/1
  # GET /roles/1.xml
  def show
    @role = Role.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @role.to_xml }
    end
  end

  # GET /roles/new
  def new
    @role = Role.new
  end

  # GET /roles/1;edit
  def edit
    @role = Role.find(params[:id])
  end

  # POST /roles
  # POST /roles.xml
  def create
    @role = Role.new(params[:role])

    # assign parent role
    @role.parent = Role.find(params[:role][:parent].to_i) if not params[:role][:parent].to_s.empty?

    respond_to do |format|
      if @role.save
        # set the roles's permissions to the permission from the parameters 
        params[:role][:permissions] = [] if params[:role][:permissions].nil?
        @role.permissions = params[:role][:permissions].collect { |i| Permission.find(i) }
        
        flash[:notice] = 'Role was successfully created.'
        format.html { redirect_to roles_url }
        format.xml  { head :created, :location => roles_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @role.errors.to_xml }
      end
    end
  end

  # PUT /roles/1
  # PUT /roles/1.xml
  def update
    @role = Role.find(params[:id])

    # set parent role
    if not params[:role][:parent].to_s.empty?
      @role.parent = Role.find(params[:role][:parent])
    else
      @role.parent = nil
    end

    # get an array of static permissions and set the permission associations
    params[:role][:permissions] = [] if params[:role][:permissions].nil?
    permissions = params[:role][:permissions].collect { |i| Permission.find(i) }
    @role.permissions = permissions
    
    respond_to do |format|
      if @role.update_attributes(params[:role])
        flash[:notice] = 'Role was successfully updated.'
        format.html { redirect_to roles_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors.to_xml }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.xml
  def destroy
    @role = Role.find(params[:id])
    @role.destroy

    respond_to do |format|
      format.html { redirect_to roles_url }
      format.xml  { head :ok }
    end
  end
end
