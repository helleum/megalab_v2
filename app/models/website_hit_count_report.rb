class WebsiteHitCountReport < ActiveRecord::Base
  require 'csv'

  validates_uniqueness_of :report_date
  
  @path = 'public/reports/web/'
  
  def self.generate_csv(date, filename)
    date_report = Date.parse(date).to_time
    report = StringIO.new
    CSV::Writer.generate(report, ',') do |csv|  
      csv << ""
      csv << ""
      csv << ["", "MEGALAB SERVICES NETWORK"]
      csv << ["","Website Hit Count Report"]
      csv << ["","(" + date_report.day.ordinalize + date_report.strftime(" %B %Y)")]
      csv << ""
      csv << ""
      csv << ['No', 'URL', 'Count' ]
      count = 1
      CSV.open(@path + filename, 'r', ' ') do |row|
        csv << [count, row[1], row[0]]
        count +=1
      end
      return report
    end
  end

end
