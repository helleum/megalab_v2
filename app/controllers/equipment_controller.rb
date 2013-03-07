class EquipmentController < ApplicationController
  layout 'popup', :except => :index
  
  auto_complete_for :seat, :display_name
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  def index
    @can_create = action_permitted?(params[:controller], 'new')
    
    query = "TRUE"
    query += [" and serial_no LIKE ", "'%" + sanitize_search(params[:serial_no]) + "%'"].to_s unless params[:serial_no].blank?
    query += [" and display_name LIKE ", "'%" + sanitize_search(params[:seat_no]) + "%'"].to_s unless params[:seat_no].blank?
    query += " and eq_condition =  \"#{sanitize_search(params[:condition])}\"" unless params[:condition].blank?         
    query += [" and hardware_address LIKE ", "'%" + sanitize_search(params[:hardware_address]) + "%'"].to_s unless params[:hardware_address].blank?
    query += [" and description LIKE ", "'%" + sanitize_search(params[:description]) + "%'"].to_s unless params[:description].blank?

    @sort = params[:sort] || 'serial_no ASC'
    @equipment = EquipmentListing.paginate :page => params[:page], :order => @sort, :conditions => query
    render :layout => 'application'
  end

  def show
    @equipment = Equipment.find(params[:id])
  end
  
  def change_condition
    @equipment = Equipment.find(params[:id])
    if request.post?
      @equipment_condition_history = @equipment.equipment_condition_histories.build(params[:equipment_condition_history])
      # This assumes action states for Condition History matches condition states for Equipment. If not then this will NOT work properly.
      @equipment_condition_history.action = EquipmentConditionHistory::ACTION_STATE.fetch(@equipment.toggle_condition_view)
      if @equipment_condition_history.save
        @equipment.toggle_condition
        flash[:notice] = 'Equipment condition was successfully updated.'
        redirect_to :action => 'show', :id => @equipment
      else
        render :action => 'change_condition'
      end
    end
  end

  def assign_seat
    @equipment = Equipment.find(params[:id])    
    if request.post? and @equipment.seat.nil?
      @seat = Seat.find_by_display_name(params[:seat][:display_name])
      # Check seat chosen have any equipment assigned to it with hardware address if current equipment has hardware address.
      @seat_check = @seat.equipment.find(:first, :conditions => 'hardware_address is not NULL AND hardware_address !=""') unless @equipment.hardware_address.blank?
      if not @seat.nil? and @seat_check.nil?
        @equipment.update_attribute('seat_id', @seat.id)
        @equipment.equipment_seat_assignment_histories.create(:action => EquipmentSeatAssignmentHistory::ACTION_STATE.fetch('Assign'), :seat_id => @seat.id)
        flash[:notice] = "Equipment has been assigned to seat (#{@seat.display_name})."
        redirect_to :action => 'show', :id => @equipment
      elsif @seat_check
        flash.now[:error] = 'Seat chosen already assigned to equipment with MAC address.'
        render :action => 'assign_seat'
      else
        flash.now[:error] = 'Invalid seat!'
        render :action => 'assign_seat'
      end
    else
      unless @equipment.seat.nil?
        flash[:error] = 'Equipment seat already assigned. Please remove assigned seat first.'
        redirect_to :action => 'show', :id => @equipment
      end
    end
  end

  def remove_seat
    @equipment = Equipment.find(params[:id])    
    if request.post? and not @equipment.seat.nil?
      @equipment.seat_remove
      @equipment.equipment_seat_assignment_histories.create(:action => EquipmentSeatAssignmentHistory::ACTION_STATE.fetch('Remove'))
      flash[:notice] = 'Equipment seat has been removed.'
      redirect_to :action => 'show', :id => @equipment
    else
      if @equipment.seat.nil?
        flash[:error] = "Equipment doesn't have a seat assigned!"
        redirect_to :action => 'show', :id => @equipment
      end
    end
  end
  
  def condition_history
    @equipment = Equipment.find(params[:id])
  end

  def seat_history
    @equipment = Equipment.find(params[:id])    
  end
  
  def new
    @equipment = Equipment.new
  end

  def create
    @equipment = Equipment.new(params[:equipment])
    if @equipment.save
      flash[:notice] = 'Equipment was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @equipment = Equipment.find(params[:id])
  end

  def update
    @equipment = Equipment.find(params[:id])
    if @equipment.update_attributes(params[:equipment])
      flash[:notice] = 'Equipment was successfully updated.'
      redirect_to :action => 'show', :id => @equipment
    else
      render :action => 'edit'
    end
  end

  def destroy
    Equipment.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
end
