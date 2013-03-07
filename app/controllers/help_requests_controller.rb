class HelpRequestsController < ApplicationController
  layout 'popup', :except => :index
  
  skip_filter :protect_with_permissions, :login_required, :only => [ :new, :create, :request_sent ] 
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  def index
    query = "TRUE"
    query += [" and id LIKE ", "'%" + sanitize_search(params[:help_id]) + "%'"].to_s unless params[:help_id].blank?
    query += [" and display_name LIKE ", "'%" + sanitize_search(params[:seat_no]) + "%'"].to_s unless params[:seat_no].blank?
    query += [" and hardware_address LIKE ", "'%" + sanitize_search(params[:hardware_address]) + "%'"].to_s unless params[:hardware_address].blank?
    query += [" and request_remark LIKE ", "'%" + sanitize_search(params[:request_remark]) + "%'"].to_s unless params[:request_remark].blank?
    query += " and status =  \"#{sanitize_search(params[:status])}\"" unless params[:status].blank?
    query += [" and created_at LIKE ", "'%" + sanitize_search(params[:date_from]) + "%'"].to_s unless params[:date_from].blank?

    @sort = params[:sort] || 'created_at DESC'
    @help_requests = HelpRequestListing.paginate :page => params[:page], :order => @sort, :conditions => query
    render :layout => 'application' 
  end

  def show
    @help_request = HelpRequest.find(params[:id])
    if @help_request.open?
      @help_request.mark_reviewed
      @help_request.help_request_monitoring_histories.create(:action => HelpRequestMonitoringHistory::ACTION_STATE.fetch('Reviewing'))
    end
    @help_history = @help_request.help_request_monitoring_histories.find(:first, :order => "id DESC")
  end

  def check_request
    @help_request = HelpRequest.find(params[:id])
    if @help_request.accepted? 
      @help_request.release_request
      @help_request.help_request_monitoring_histories.create(:action => HelpRequestMonitoringHistory::ACTION_STATE.fetch('Release'))
      flash[:notice] = "Help Request ID (#{@help_request.id}) has been released."
      redirect_to :action => 'index'
    else
      @help_request.accept_request
      @help_request.help_request_monitoring_histories.create(:action => HelpRequestMonitoringHistory::ACTION_STATE.fetch('Accept'))
      flash[:notice] = "You have accepted Help Request ID (#{@help_request.id})."
      redirect_to :action => 'show', :id => @help_request
    end 
  end

  def close_request
    @help_request = HelpRequest.find(params[:id])
    if request.post? and not @help_request.closed?
      params[:help_request][:status] = HelpRequest::STATUS_STATE.fetch('Closed')
      if @help_request.update_attributes(params[:help_request])
        @help_request.help_request_monitoring_histories.create(:action => HelpRequestMonitoringHistory::ACTION_STATE.fetch('Close'))
        flash[:notice] = "Help Request ID (#{@help_request.id}) is now closed."
        redirect_to :action => 'show', :id => @help_request
      else
        render :action => 'close_request'
      end
    else
      unless @help_request.accepted?
        flash[:error] = "Help Request ID (#{@help_request.id}) is not in accepted status."
        redirect_to :action => 'show', :id => @help_request
      end
    end
  end

  def request_history
    @help_request = HelpRequest.find(params[:id])
  end

  def new
    @help_request = HelpRequest.new
    render :layout => "help_request" 
  end

  def create
    @help_request = HelpRequest.new(params[:help_request])
    hardware_address = params[:help_request][:hardware_address].split(',')
  
    hardware_address.each do |addr|
      if addr.length == 12
        @equipment = Equipment.find(:first, :conditions => [ 'hardware_address = ?', addr.upcase ])    
        @help_request.hardware_address = addr.upcase
        @help_request.seat_id = @equipment.seat_id unless @equipment.blank? 
      end        
    end

    @help_request.status = HelpRequest::STATUS_STATE.fetch('Open')
    if @help_request.save_with_captcha
      @help_request.help_request_monitoring_histories.create(:action => HelpRequestMonitoringHistory::ACTION_STATE.fetch('Open'))            
      redirect_to :action => 'request_sent'
    else
      render :action => 'new', :layout => "help_request"
    end  
  end

  def request_sent
    render :layout => "help_request"     
  end
  
  def edit
    @help_request = HelpRequest.find(params[:id])
  end

  def update
    @help_request = HelpRequest.find(params[:id])
    if @help_request.update_attributes(params[:help_request])
      flash[:notice] = 'HelpRequest was successfully updated.'
      redirect_to :action => 'show', :id => @help_request
    else
      render :action => 'edit'
    end
  end

  def destroy
    HelpRequest.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
end
