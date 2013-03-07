class Report < ActiveRecord::Base
  require 'csv'

  class << self
    
    def vouchers_issued_query(from, to)
      vouchers_issued_sql = <<REPORT_SQL
        SELECT DATE_FORMAT(created_at, "%e %b, %Y") AS `Date`,
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 000000 AND 005959) AND action=1, 1, 0)) AS "00:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 010000 AND 015959) AND action=1, 1, 0)) AS "01:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 020000 AND 025959) AND action=1, 1, 0)) AS "02:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 030000 AND 035959) AND action=1, 1, 0)) AS "03:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 080000 AND 085959) AND action=1, 1, 0)) AS "08:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 090000 AND 095959) AND action=1, 1, 0)) AS "09:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 100000 AND 105959) AND action=1, 1, 0)) AS "10:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 110000 AND 115959) AND action=1, 1, 0)) AS "11:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 120000 AND 125959) AND action=1, 1, 0)) AS "12:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 130000 AND 135959) AND action=1, 1, 0)) AS "13:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 140000 AND 145959) AND action=1, 1, 0)) AS "14:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 150000 AND 155959) AND action=1, 1, 0)) AS "15:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 160000 AND 165959) AND action=1, 1, 0)) AS "16:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 170000 AND 175959) AND action=1, 1, 0)) AS "17:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 180000 AND 185959) AND action=1, 1, 0)) AS "18:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 190000 AND 195959) AND action=1, 1, 0)) AS "19:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 200000 AND 205959) AND action=1, 1, 0)) AS "20:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 210000 AND 215959) AND action=1, 1, 0)) AS "21:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 220000 AND 225959) AND action=1, 1, 0)) AS "22:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 230000 AND 235959) AND action=1, 1, 0)) AS "23:00",
        SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 000000 AND 035959) AND action=1, 1, 0) +
        IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 080000 AND 235959) AND action=1, 1, 0)) as Total,
        (SUM(IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 000000 AND 035959) AND action=1, 1, 0) +
        IF((DATE_FORMAT(created_at, "%H%i%s") BETWEEN 080000 AND 235959) AND action=1, 1, 0)) / 40) as Average
        FROM megalab_production.user_seat_assignment_histories u
        WHERE created_at BETWEEN '#{from}' AND '#{to}'
        GROUP BY date_format(created_at, "%b %e %y")
        ORDER BY created_at
REPORT_SQL
      return connection.select_all(vouchers_issued_sql)
    rescue
      nil
    end

    def vouchers_issued_csv(from, to)
      queries = vouchers_issued_query(from, to)
      date_from = Date.parse(from).to_time
      date_to = Date.parse(to).to_time - 1.day
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |csv|  
        csv << ""
        csv << ""
        csv << ["MEGALAB SERVICES NETWORK"]
        csv << ["Vouchers Issued Report"]
        csv << ["(" + date_from.day.ordinalize + date_from.strftime(" %B") + " - " + date_to.day.ordinalize + date_to.strftime(" %B %Y)")]
        csv << ""
        csv << ""
        csv << ['Date', '00:00', '01:00', '02:00', '03:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00', 'Total', 'Average' ]
        queries.each do |h|
          csv << [h.fetch("Date"), h.fetch("00:00"), h.fetch("01:00"), h.fetch("02:00"), h.fetch("03:00"), h.fetch("08:00"), h.fetch("09:00"), h.fetch("10:00"), h.fetch("11:00"), h.fetch("12:00"), h.fetch("13:00"), h.fetch("14:00"), h.fetch("15:00"), h.fetch("16:00"), h.fetch("17:00"), h.fetch("18:00"), h.fetch("19:00"), h.fetch("20:00"), h.fetch("21:00"), h.fetch("22:00"), h.fetch("23:00"), h.fetch("Total"), h.fetch("Average") ]
        end  
      end
      report
    end
    
# report query updated on 29/06/2012 by Joshua
    def lab_machine_usage_query(from, to)
      lab_machine_usage_sql = <<REPORT_SQL
		SELECT DATE_FORMAT(AcctStartTime, "%e %b, %Y") AS `Date`,
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 000000 AND 005959) 
        OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 000000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 000000)), 1, 0)) AS "00:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 010000 AND 015959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 010000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 010000)), 1, 0)) AS "01:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 020000 AND 025959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 020000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 020000)), 1, 0)) AS "02:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 030000 AND 035959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 030000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 030000)), 1, 0)) AS "03:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 080000 AND 085959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 080000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 080000)), 1, 0)) AS "08:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 090000 AND 095959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 090000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 090000)), 1, 0)) AS "09:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 100000 AND 105959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 100000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 100000)), 1, 0)) AS "10:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 110000 AND 115959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 110000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 110000)), 1, 0)) AS "11:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 120000 AND 125959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 120000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 120000)), 1, 0)) AS "12:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 130000 AND 135959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 130000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 130000)), 1, 0)) AS "13:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 140000 AND 145959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 140000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 140000)), 1, 0)) AS "14:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 150000 AND 155959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >=150000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 150000)), 1, 0)) AS "15:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 160000 AND 165959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 160000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 160000)), 1, 0)) AS "16:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 170000 AND 175959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 170000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 170000)), 1, 0)) AS "17:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 180000 AND 185959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 180000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 180000)), 1, 0)) AS "18:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 190000 AND 195959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 190000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 190000)), 1, 0)) AS "19:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 200000 AND 205959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 200000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 200000)), 1, 0)) AS "20:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 210000 AND 215959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 210000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 210000)), 1, 0)) AS "21:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 220000 AND 225959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >=220000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 220000)), 1, 0)) AS "22:00",
        SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 230000 AND 235959) OR 
		((DATE_FORMAT(AcctStopTime, "%H%i%s") >=230000) AND
        (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 230000)), 1, 0)) AS "23:00" 
		FROM radius.radacct
		WHERE AcctStartTime BETWEEN '#{from}' AND '#{to}'
		AND UserName NOT IN ('g0001', 'tc001')
		GROUP BY DATE_FORMAT(AcctStartTime, "%d %m %Y")
		ORDER BY AcctStartTime
REPORT_SQL
      return connection.select_all(lab_machine_usage_sql)
    rescue
      nil
    end
# report query updated on 18/01/2011 by Joshua, Siti & Judith
    
    def lab_machine_usage_csv(from, to)
      queries = lab_machine_usage_query(from, to)
      date_from = Date.parse(from).to_time
      date_to = Date.parse(to).to_time - 1.day
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |csv|  
        csv << ""
        csv << ""
        csv << ["MEGALAB SERVICES NETWORK"]
        csv << ["Cumulative Lab Machine Usage Report"]
        csv << ["(" + date_from.day.ordinalize + date_from.strftime(" %B") + " - " + date_to.day.ordinalize + date_to.strftime(" %B %Y)")]
        csv << ""
        csv << ""
        csv << ['Date', '00:00', '01:00', '02:00', '03:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00' ]
        queries.each do |h|
          csv << [h.fetch("Date"), h.fetch("00:00"), h.fetch("01:00"), h.fetch("02:00"), h.fetch("03:00"), h.fetch("08:00"), h.fetch("09:00"), h.fetch("10:00"), h.fetch("11:00"), h.fetch("12:00"), h.fetch("13:00"), h.fetch("14:00"), h.fetch("15:00"), h.fetch("16:00"), h.fetch("17:00"), h.fetch("18:00"), h.fetch("19:00"), h.fetch("20:00"), h.fetch("21:00"), h.fetch("22:00"), h.fetch("23:00") ]
        end  
      end
      report
    end

    # Query without grouping so a user can pop up multiple times in the report if user used lab more than once in a day.
    def user_usage_query_without_grouping(from, to)
      user_usage_sql = <<REPORT_SQL
        SELECT u.idcard_no1, u.full_name, if(ISNULL(s.display_name), '', s.display_name) as display_name,
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 000000 AND 005959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 000000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 000000)), 'IN', '') AS "00:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 010000 AND 015959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 010000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 010000)), 'IN', '') AS "01:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 020000 AND 025959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 020000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 020000)), 'IN', '') AS "02:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 030000 AND 035959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 030000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 030000)), 'IN', '') AS "03:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 080000 AND 085959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 080000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 080000)), 'IN', '') AS "08:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 090000 AND 095959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 090000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 090000)), 'IN', '') AS "09:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 100000 AND 105959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 100000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 100000)), 'IN', '') AS "10:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 110000 AND 115959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 110000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 110000)), 'IN', '') AS "11:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 120000 AND 125959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 120000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 120000)), 'IN', '') AS "12:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 130000 AND 135959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 130000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 130000)), 'IN', '') AS "13:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 140000 AND 145959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 140000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 140000)), 'IN', '') AS "14:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 150000 AND 155959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 150000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 150000)), 'IN', '') AS "15:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 160000 AND 165959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 160000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 160000)), 'IN', '') AS "16:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 170000 AND 175959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 170000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 170000)), 'IN', '') AS "17:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 180000 AND 185959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 180000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 180000)), 'IN', '') AS "18:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 190000 AND 195959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 190000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 190000)), 'IN', '') AS "19:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 200000 AND 205959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 200000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 200000)), 'IN', '') AS "20:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 210000 AND 215959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 210000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 210000)), 'IN', '') AS "21:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 220000 AND 225959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 220000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 220000)), 'IN', '') AS "22:00",
        IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 230000 AND 235959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 230000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 230000)), 'IN', '') AS "23:00"
        FROM radius.radacct r
        JOIN megalab_production.users u ON r.user_id = u.id
        LEFT JOIN megalab_production.equipment e ON REPLACE(r.CallingStationId, '-', '') = e.hardware_address
        LEFT JOIN megalab_production.seats s ON e.seat_id = s.id
        WHERE AcctStartTime BETWEEN '#{from}' AND '#{to}'
        ORDER BY full_name
REPORT_SQL
      return connection.select_all(user_usage_sql)
    rescue
      nil
    end    
    
    # Query with grouping so a user will only show up once in the report if user used lab more than once in a day. Multiple lab use will be summed up in one row.
    def user_usage_query_with_grouping(from, to)
      user_usage_sql = <<REPORT_SQL
        SELECT u.idcard_no1, u.full_name,
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 000000 AND 005959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 000000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 000000)), 1, 0)) = 0, '', 'IN') AS "00:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 010000 AND 015959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 010000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 010000)), 1, 0)) = 0, '', 'IN') AS "01:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 020000 AND 025959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 020000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 020000)), 1, 0)) = 0, '', 'IN') AS "02:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 030000 AND 035959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 030000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 030000)), 1, 0)) = 0, '', 'IN') AS "03:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 080000 AND 085959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 080000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 080000)), 1, 0)) = 0, '', 'IN') AS "08:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 090000 AND 095959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 090000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 090000)), 1, 0)) = 0, '', 'IN') AS "09:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 100000 AND 105959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 100000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 100000)), 1, 0)) = 0, '', 'IN') AS "10:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 110000 AND 115959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 110000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 110000)), 1, 0)) = 0, '', 'IN') AS "11:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 120000 AND 125959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 120000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 120000)), 1, 0)) = 0, '', 'IN') AS "12:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 130000 AND 135959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 130000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 130000)), 1, 0)) = 0, '', 'IN') AS "13:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 140000 AND 145959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 140000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 140000)), 1, 0)) = 0, '', 'IN') AS "14:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 150000 AND 155959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 150000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 150000)), 1, 0)) = 0, '', 'IN') AS "15:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 160000 AND 165959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 160000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 160000)), 1, 0)) = 0, '', 'IN') AS "16:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 170000 AND 175959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 170000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 170000)), 1, 0)) = 0, '', 'IN') AS "17:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 180000 AND 185959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 180000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 180000)), 1, 0)) = 0, '', 'IN') AS "18:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 190000 AND 195959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 190000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 190000)), 1, 0)) = 0, '', 'IN') AS "19:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 200000 AND 205959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 200000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 200000)), 1, 0)) = 0, '', 'IN') AS "20:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 210000 AND 215959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 210000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 210000)), 1, 0)) = 0, '', 'IN') AS "21:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 220000 AND 225959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 220000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 220000)), 1, 0)) = 0, '', 'IN') AS "22:00",
        IF(SUM(IF((DATE_FORMAT(AcctStartTime, "%H%i%s") BETWEEN 230000 AND 235959) OR ((DATE_FORMAT(AcctStopTime, "%H%i%s") >= 230000) AND (DATE_FORMAT(AcctStartTime, "%H%i%s") <= 230000)), 1, 0)) = 0, '', 'IN') AS "23:00"
      	FROM radius.radacct r, megalab_production.users u
        WHERE AcctStartTime BETWEEN '#{from}' AND '#{to}'
        AND r.UserName = u.idcard_no1
        GROUP BY u.idcard_no1
        ORDER BY u.full_name
REPORT_SQL
      return connection.select_all(user_usage_sql)
    rescue
      nil
    end    

    def user_usage_csv(from, to)
      queries = user_usage_query_with_grouping(from, to)
      date_from = Date.parse(from).to_time
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |csv|  
        csv << ""
        csv << ""
        csv << ["","MEGALAB SERVICES NETWORK"]
        csv << ["","User Usage Report"]
        csv << ["","(" + date_from.day.ordinalize + date_from.strftime(" %B %Y)")]
        csv << ""
        csv << ""
        csv << ['ID Card No 1','Full Name', '00:00', '01:00', '02:00', '03:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00' ]
        queries.each do |h|
          csv << [h.fetch("idcard_no1"), h.fetch("full_name"), h.fetch("00:00"), h.fetch("01:00"), h.fetch("02:00"), h.fetch("03:00"), h.fetch("08:00"), h.fetch("09:00"), h.fetch("10:00"), h.fetch("11:00"), h.fetch("12:00"), h.fetch("13:00"), h.fetch("14:00"), h.fetch("15:00"), h.fetch("16:00"), h.fetch("17:00"), h.fetch("18:00"), h.fetch("19:00"), h.fetch("20:00"), h.fetch("21:00"), h.fetch("22:00"), h.fetch("23:00") ]
        end  
      end
      report
    end

  end
end
