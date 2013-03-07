class ReportsController < ApplicationController
  layout 'popup', :except => :index

  @@date_format = "%Y-%m-%d"

  def index
    render :layout => 'application'
  end

  def vouchers_issued
    if request.post?
      if not current_user.has_role?("Root")
        start_date = date_month_year_select(sanitize_search(params[:date][:month]), sanitize_search(params[:date][:year]))
        end_date = date_month_next(start_date)
      else
        start_date = date_month_begin(sanitize_search(params[:date_from])) if not params[:date_from].blank?
        if not start_date.blank? and not params[:date_to].blank?
          if params[:date_exact]
            start_date = date_day_start(sanitize_search(params[:date_from]))
            end_date = date_day_next(sanitize_search(params[:date_to]))
          else
            end_date = date_month_begin(sanitize_search(params[:date_to]))
            end_date = date_month_next(end_date) if start_date == end_date
          end
        elsif not start_date.blank?
          end_date = date_month_next(start_date)
        else
          flash.now[:error] = 'No date selected.'
        end
      end
      unless start_date.blank?
        report = Report.vouchers_issued_csv(start_date, end_date)
        report.rewind
        send_data(report.read, :type => 'text/csv; charset=iso-8859-1; header=present', :filename => start_date + '-to-' + (Date.parse(end_date).to_time - 1.day).strftime(@@date_format) + '-vouchers_issued-' + Time.now.strftime("%Y%m%d-%H%M%S") + '.csv', :disposition =>'attachment', :encoding => 'utf8')
      end
    end
  end

  def website_hit_count
    if request.post?
#      if params[:date].blank? or params[:date][:year].blank? or params[:date][:month].blank?
#        flash[:error] = "Month and Year are required."
#        redirect_to :action => :website_hit_count
#      end      
      date_from = Date.parse(sanitize_search(params[:date][:year]) + "-" + sprintf("%02d", sanitize_search(params[:date][:month]))).strftime(@@date_format)
      date_to = date_month_end(date_from)
    else
      date_from = Time.now.beginning_of_month.strftime(@@date_format)
      date_to = date_month_end(date_from)
    end
    @reports = WebsiteHitCountReport.find(:all, :conditions => ['report_date BETWEEN ? AND ?', date_from, date_to], :order => 'report_date')
  end

  def website_hit_count_csv
    check = WebsiteHitCountReport.find_by_report_date(sanitize_search(params[:date]))
    if check
      report = WebsiteHitCountReport.generate_csv(check.report_date.strftime(@@date_format), check.filename)
      report.rewind
      send_data(report.read, :type => 'text/csv; charset=iso-8859-1; header=present', :filename => params[:date] + '-website_hit_count-' + Time.now.strftime("%Y%m%d-%H%M%S") + '.csv', :disposition =>'attachment', :encoding => 'utf8')
    else
      flash[:error] = "Invalid report date!"
      redirect_to :action => :website_hit_count
    end
  end

  def cumulative_lab_machine_usage
    if request.post?
      if not current_user.has_role?("Root")
        start_date = date_month_year_select(sanitize_search(params[:date][:month]), sanitize_search(params[:date][:year]))
        end_date = date_month_next(start_date)
      else
        start_date = date_month_begin(sanitize_search(params[:date_from])) if not params[:date_from].blank?
        if not start_date.blank? and not params[:date_to].blank?
          if params[:date_exact]
            start_date = date_day_start(sanitize_search(params[:date_from]))
            end_date = date_day_next(sanitize_search(params[:date_to]))
          else
            end_date = date_month_begin(sanitize_search(params[:date_to]))
            end_date = date_month_next(end_date) if start_date == end_date
          end
        elsif not start_date.blank?
          end_date = date_month_next(start_date)
        else
          flash.now[:error] = 'No date selected.'
        end
      end
      unless start_date.blank?
        report = Report.lab_machine_usage_csv(start_date, end_date)
        report.rewind
        send_data(report.read, :type => 'text/csv; charset=iso-8859-1; header=present', :filename => start_date + '-to-' + (Date.parse(end_date).to_time - 1.day).strftime(@@date_format) + '-cumulative_lab_machine_usage-' + Time.now.strftime("%Y%m%d-%H%M%S") + '.csv', :disposition =>'attachment', :encoding => 'utf8')
      end
    end
  end

  def user_usage
    unless (Time.now.hour > 0 and Time.now.hour < 8) or current_user.has_role?("Administrator", "Root")
      flash[:error] = "Report generation not allowed!"
      redirect_to :action => :index
    end      

    if request.post?
      start_date = date_day_start(sanitize_search(params[:date_from])) if not params[:date_from].blank?
      if not start_date.blank?
        end_date = date_day_next(sanitize_search(params[:date_from]))
      else
        flash.now[:error] = 'No date selected.'
      end
      unless start_date.blank?
        report = Report.user_usage_csv(start_date, end_date)
        report.rewind
        send_data(report.read, :type => 'text/csv; charset=iso-8859-1; header=present', :filename => start_date + '-user_usage-' + Time.now.strftime("%Y%m%d-%H%M%S") + '.csv', :disposition =>'attachment', :encoding => 'utf8')
      end
    end
  end
  
  protected
  
  def date_month_begin(date)
    Date.parse(date).to_time.beginning_of_month.strftime(@@date_format)
  end

  def date_month_end(date)
    Date.parse(date).to_time.end_of_month.strftime(@@date_format)
  end

  def date_month_next(date)
    Date.parse(date).to_time.end_of_month.tomorrow.strftime(@@date_format)
  end

  def date_day_start(date)
    Date.parse(date).strftime(@@date_format)
  end

  def date_day_next(date)
    (Date.parse(date).to_time + 1.day).strftime(@@date_format)    
  end

  def date_month_year_select(month, year)
    Date.parse(year + "-" + sprintf("%02d", month)).strftime(@@date_format)    
  end
end
