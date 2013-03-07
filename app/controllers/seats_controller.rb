class SeatsController < ApplicationController
  layout 'popup', :except => :index

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  def index
    @can_create = action_permitted?(params[:controller], 'new')
   
    query = "TRUE"
    query += [" and display_name LIKE ", "'%" + sanitize_search(params[:display_name]) + "%'"].to_s unless params[:display_name].blank?
    query += [" and user_name LIKE ", "'%" + sanitize_search(params[:user_name]) + "%'"].to_s unless params[:user_name].blank?
    query += [" and full_name LIKE ", "'%" + sanitize_search(params[:full_name]) + "%'"].to_s unless params[:full_name].blank?
    query += " and duration =  \"#{sanitize_search(params[:duration]).minute}\"" unless params[:duration].blank?
    query += " and status =  \"#{sanitize_search(params[:status])}\"" unless params[:status].blank?
    query += " and st_condition =  \"#{sanitize_search(params[:condition])}\"" unless params[:condition].blank?
    
    @sort = params[:sort] || 'display_name ASC'
    @seats = SeatListing.paginate :page => params[:page], :order => @sort, :conditions => query
    render :layout => 'application'
  end

  def show
    @seat = Seat.find(params[:id])
  end

  def change_condition
    @seat = Seat.find(params[:id])
    if request.post?
      @seat_condition_history = @seat.seat_condition_histories.build(params[:seat_condition_history])
      # This assumes action states for Condition History matches condition states for Seat. If not then this will NOT work properly.
      @seat_condition_history.action = params[:seat][:condition]
      if @seat_condition_history.save
        @seat.update_attribute('condition', params[:seat][:condition])
        flash[:notice] = 'Seat condition was successfully updated.'
        redirect_to :action => 'show', :id => @seat
      else
        render :action => 'change_condition'
      end
    end
  end
  
  def update_multiple_seats_condition
    from = params[:from].to_i
    to = params[:to].to_i
    if from - to > 0 
      flash[:error]= "Seat No Range invalid"
    end
    @seat_ids = Seat.generate_seat(from, to)
     
     @seat_ids.each do |seat_id|  
     seat = Seat.find(seat_id.to_i)
        @seat_condition_history = seat.seat_condition_histories.build(params[:seat_condition_history])
        @seat_condition_history.action = params[:condition]
      if @seat_condition_history.save
     seat.update_attribute(:condition, params[:condition])
      flash[:notice] = 'Seats condition were successfully updated.'
    end
  end
 end

  
  def condition_history
    @seat = Seat.find(params[:id])
  end
  
  def user_seat_history
    query = "TRUE"
    query += [" and users.full_name LIKE ", "'%" + sanitize_search(params[:full_name]) + "%'"].to_s unless params[:full_name].blank?
    query += [" and seats.display_name LIKE ", "'%" + sanitize_search(params[:display_name]) + "%'"].to_s unless params[:display_name].blank?
    query += " and user_seat_assignment_histories.duration =  \"#{sanitize_search(params[:duration]).minute}\"" unless params[:duration].blank?
    query += " and user_seat_assignment_histories.action = \"#{sanitize_search(params[:action_done])}\"" unless params[:action_done].blank?
    query += [" and action_remark LIKE ", "'%" + sanitize_search(params[:action_remark]) + "%'"].to_s unless params[:action_remark].blank?
    query += [" and created_bies_user_seat_assignment_histories.full_name LIKE ", "'%" + sanitize_search(params[:action_by]) + "%'"].to_s unless params[:action_by].blank?
    if not params[:date_from].blank? and not params[:date_to].blank?
      query += " and user_seat_assignment_histories.created_at BETWEEN \"#{sanitize_search(params[:date_from])}\" AND \"#{(sanitize_search(params[:date_to]))}\""
    elsif not params[:date_from].blank?
      query += [" and user_seat_assignment_histories.created_at LIKE ", "'" + sanitize_search(params[:date_from]) + "%'"].to_s
    end

    @sort = params[:sort] || 'user_seat_assignment_histories.created_at DESC'
    @seats = UserSeatAssignmentHistory.paginate :page => params[:page], :order => @sort, :include => [ :seat, :user, :created_by ], :conditions => query
  end
  
  def new
    @seat = Seat.new
  end

  def create
    @seat = Seat.new(params[:seat])
    if @seat.save
      flash[:notice] = 'Seat was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @seat = Seat.find(params[:id])
  end

  def update
    @seat = Seat.find(params[:id])
    if @seat.update_attributes(params[:seat])
      flash[:notice] = 'Seat was successfully updated.'
      redirect_to :action => 'show', :id => @seat
    else
      render :action => 'edit'
    end
  end

  def destroy
    Seat.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
end
