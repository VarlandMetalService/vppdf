# Class for printing time card report.
class Timecards < VarlandPdf

  # Constructor.
  def initialize(period = nil, easter = false)

    # Call parent constructor.
    super()

    # Load data.
    if period.blank?
      self.load_sample_data
    else
      @period = period
      @easter = easter
      self.load_data
    end

    # Draw data.
    self.draw_data

  end

  # Loads sample data.
  def load_sample_data
    @data = self.load_sample("period")
  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://timeclock.varland.com/periods/#{@period}.json")
  end

  # Prints data.
  def draw_data

    # Initialize column number.
    col = 1

    # Draw time card for each employee.
    @data[:employees].each do |e|

      # Skip or show based on Easter Seals flag.
      if (e[:employee_number] >= 1000 && e[:employee_number] < 1100)
        next unless @easter
      else
        next if @easter
      end
      #next if e[:employee_number] >= 1000 && e[:employee_number] < 1100 && !@easter
      #next if (e[:employee_number] < 1000 || e[:employee_number] >= 1100) && @easter

      # Start new page if necessary.
      if col == 2
        self.start_new_page
        col = 1
      end

      # Set x and y coordinates for employee.
      x = ((col - 1) * 4.25) + 0.25
      y = 10.75

      # Draw box for employee # and period ending date.
      self.rect(x, y, 3.75, 0.4)
      text = "NO."
      offset = 0
      width = 1.25
      self.txtb(text, x + offset, y, width, 0.4, h_align: :left, h_pad: 0.05, font_size: 10, style: :bold)
      field_width = self.calc_width(text, size: 10, style: :bold)
      line_length = width - 0.05 - field_width
      self.hline(x + offset + 0.1 + field_width, y - 0.3, line_length, line_width: 0.005)
      self.txtb(e[:employee_number], x + offset + 0.1 + field_width, y - 0.1, line_length, 0.2, font_size: 10, style: :bold, h_align: :center)
      text = "WEEK ENDING"
      offset = 1.5
      width = 2.15
      self.txtb(text, x + offset, y, width, 0.4, h_align: :left, h_pad: 0.05, font_size: 10, style: :bold)
      field_width = self.calc_width(text, size: 10, style: :bold)
      line_length = width - 0.05 - field_width
      self.hline(x + offset + 0.1 + field_width, y - 0.3, line_length, line_width: 0.005)
      self.txtb(Date.parse(@data[:period_ending_date]).strftime("%m/%d/%Y"), x + offset + 0.1 + field_width, y - 0.1, line_length, 0.2, font_size: 10, style: :bold, h_align: :center)
      y -= 0.4

      # Draw box for employee name.
      self.vline(x, y, 0.4)
      self.vline(x + 3.75, y, 0.4)
      text = "NAME"
      offset = 0
      width = 3.65
      self.txtb(text, x + offset, y, width, 0.4, h_align: :left, h_pad: 0.05, font_size: 10, style: :bold)
      field_width = self.calc_width(text, size: 10, style: :bold)
      line_length = width - 0.05 - field_width
      self.hline(x + offset + 0.1 + field_width, y - 0.3, line_length, line_width: 0.005)
      self.txtb(e[:name], x + offset + 0.1 + field_width, y - 0.1, line_length, 0.2, font_size: 10, style: :bold, h_align: :center)
      y -= 0.4

      # Top of time card table.
      self.txtb("Paid Non-Working Hours", x, y, 1.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      self.txtb("PT transfer to Vac", x + 1.7, y, 1.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
      self.rect(x + 3.25, y, 0.5, 0.25)
      y -= 0.25
      self.txtb("Type", x, y, 1.05, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
      self.txtb("Hours", x + 1.05, y, 0.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      self.txtb("Unpaid Hours", x + 1.7, y, 1.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
      self.rect(x + 3.25, y, 0.5, 0.25)
      y -= 0.25
      self.txtb("Vacation", x, y, 1.05, 0.25, line_color: "000000", size: 8, style: :normal, h_align: :left, h_pad: 0.05)
      self.rect(x + 1.05, y, 0.5, 0.25)
      self.vline(x + 3.75, y, 0.25)
      y -= 0.25
      self.txtb("Personal", x, y, 1.05, 0.25, line_color: "000000", size: 8, style: :normal, h_align: :left, h_pad: 0.05)
      self.rect(x + 1.05, y, 0.5, 0.25)
      self.hline(x + 1.7, y, 2.05)
      self.vline(x + 1.7, y, 0.5)
      self.vline(x + 3.75, y, 0.25)
      self.txtb("Working Hours", x + 1.7, y, 2.05, 0.25, size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      y -= 0.25
      self.txtb("Holiday", x, y, 1.05, 0.25, line_color: "000000", size: 8, style: :normal, h_align: :left, h_pad: 0.05)
      self.rect(x + 1.05, y, 0.5, 0.25)
      self.txtb("1<sup>st</sup>", x + 2.25, y, 0.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      self.txtb("2<sup>nd</sup>/3<sup>rd</sup>", x + 2.75, y, 0.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      self.txtb("Total", x + 3.25, y, 0.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      y -= 0.25
      self.txtb("L.T. Sick", x, y, 1.05, 0.25, line_color: "000000", size: 8, style: :normal, h_align: :left, h_pad: 0.05)
      self.rect(x + 1.05, y, 0.5, 0.25)
      self.txtb("Reg", x + 1.7, y, 0.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
      if e[:error]
        self.rect(x + 2.25, y, 0.5, 0.25)
        self.rect(x + 2.75, y, 0.5, 0.25)
        self.rect(x + 3.25, y, 0.5, 0.25)
      else
        self.txtb(self.format_number(e[:first_shift_regular], decimals: 2), x + 2.25, y, 0.5, 0.25, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05)
        self.txtb(self.format_number(e[:other_shift_regular], decimals: 2), x + 2.75, y, 0.5, 0.25, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05)
        self.txtb(self.format_number(e[:first_shift_regular] + e[:other_shift_regular], decimals: 2), x + 3.25, y, 0.5, 0.25, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05)
      end
      y -= 0.25
      self.txtb("Funeral", x, y, 1.05, 0.25, line_color: "000000", size: 8, style: :normal, h_align: :left, h_pad: 0.05)
      self.rect(x + 1.05, y, 0.5, 0.25)
      self.txtb("OT", x + 1.7, y, 0.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
      if e[:error]
        self.rect(x + 2.25, y, 0.5, 0.25)
        self.rect(x + 2.75, y, 0.5, 0.25)
        self.rect(x + 3.25, y, 0.5, 0.25)
      else
        self.txtb(self.format_number(e[:first_shift_overtime], decimals: 2), x + 2.25, y, 0.5, 0.25, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05, color: (e[:first_shift_overtime] > 0 ? "000000" : "000000"))
        self.txtb(self.format_number(e[:other_shift_overtime], decimals: 2), x + 2.75, y, 0.5, 0.25, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05, color: (e[:other_shift_overtime] > 0 ? "000000" : "000000"))
        self.txtb(self.format_number(e[:first_shift_overtime] + e[:other_shift_overtime], decimals: 2), x + 3.25, y, 0.5, 0.25, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05, color: ((e[:first_shift_overtime] + e[:other_shift_overtime]) > 0 ? "000000" : "000000"))
      end
      y -= 0.25
      self.txtb("Occup. Injury", x, y, 1.05, 0.25, line_color: "000000", size: 8, style: :normal, h_align: :left, h_pad: 0.05)
      self.rect(x + 1.05, y, 0.5, 0.25)
      if e[:remote].blank? || e[:remote] == 0 || e[:error]
        self.txtb("Remote", x + 1.7, y, 1.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
        self.rect(x + 3.25, y, 0.5, 0.25)
      else
        self.txtb("Remote", x + 1.7, y, 1.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05, fill_color: "ffff00")
        self.txtb(self.format_number(e[:remote], decimals: 2), x + 3.25, y, 0.5, 0.25, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05, color: "000000", fill_color: "ffff00")
      end
      y-= 0.25
      self.rect(x, y, 1.05, 0.25)
      self.rect(x + 1.05, y, 0.5, 0.25)
      self.txtb("Total Paid Non-Work Hours", x + 1.7, y, 1.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
      self.rect(x + 3.25, y, 0.5, 0.25)
      y -= 0.25
      self.rect(x, y, 1.05, 0.25)
      self.rect(x + 1.05, y, 0.5, 0.25)
      self.txtb("Total Paid Hours", x + 1.7, y, 1.55, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :left, h_pad: 0.05)
      self.rect(x + 3.25, y, 0.5, 0.25)
      y -= 0.25
      self.hline(x + 1.55, y, 0.15)
      self.txtb("Daily Totals", x + 2.25, y, 1.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      y -= 0.25
      self.txtb("1<sup>st</sup>", x + 2.25, y, 0.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      self.txtb("2<sup>nd</sup>/3<sup>rd</sup>", x + 2.75, y, 0.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      self.txtb("Total", x + 3.25, y, 0.5, 0.25, line_color: "000000", size: 8, style: :bold, h_align: :center, h_pad: 0.05)
      y -= 0.25

      # Print employee shifts.
      line_height = 0.2
      if e[:error]
        y -= line_height
        notes_box_height = y - line_height
        self.txtb(e[:error_msg], x, y, 3.75, notes_box_height, h_align: :left, v_align: :top, size: 8, style: :bold, color: "000000")
      else
        notes = []
        e[:shifts].each do |s|
          break_warning = s[:break_length] >= 46 || (s[:total_hours] < 11 && s[:break_length] >= 31)
          #puts "***Extended break***" if break_warning
          shift_height = s[:punches].length * line_height
          self.rect(x, y, 2.25, shift_height, fill_color: (s[:remote_hours] > 0 ? "ffff00" : nil))
          if s[:punches].length == 1
            self.rect(x + 2.25, y, 0.5, shift_height)
            self.rect(x + 2.75, y, 0.5, shift_height)
            self.rect(x + 3.25, y, 0.5, shift_height)
          else
            self.txtb(s[:first_shift_hours] == 0 ? "–" : self.format_number(s[:first_shift_hours], decimals: 2), x + 2.25, y, 0.5, shift_height, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05, v_align: :center, fill_color: (s[:remote_hours] > 0 ? "ffff00" : nil))
            self.txtb(s[:other_shift_hours] == 0 ? "–" : self.format_number(s[:other_shift_hours], decimals: 2), x + 2.75, y, 0.5, shift_height, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05, v_align: :center, fill_color: (s[:remote_hours] > 0 ? "ffff00" : nil))
            self.txtb(s[:total_hours] == 0 ? "–" : self.format_number(s[:total_hours], decimals: 2), x + 3.25, y, 0.5, shift_height, line_color: "000000", size: 8, h_align: :right, h_pad: 0.05, v_align: :center, fill_color: (s[:remote_hours] > 0 ? "ffff00" : nil))
          end
          s[:punches].each do |p|
            text = "#{Time.parse(p[:timestamp]).strftime("%a %m/%d %I:%M %P")} – #{p[:type].titleize}"
            if break_warning && p[:type] == "end_break"
              notes << "<u><strong><color rgb=\"000000\"><font size=\"10\">NOTES</font></color></strong></u>" if notes.length == 0
              note = "<sup><strong><color rgb=\"000000\">#{notes.length}</color></strong></sup> <strong>System: Break Exceeds #{s[:total_hours] >= 11 ? "45" : "30"} Minutes</strong>"
              note += "<br>#{s[:break_length].to_i} minutes"
              notes << note
              text += " <sup><strong><color rgb=\"000000\">#{notes.length - 1}</color></strong></sup>"
              break_warning = false
            end
            if p[:edited]
              notes << "<u><strong><color rgb=\"000000\"><font size=\"10\">NOTES</font></color></strong></u>" if notes.length == 0
              note = "<sup><strong><color rgb=\"000000\">#{notes.length}</color></strong></sup> <strong>#{p[:edited_by]}: #{p[:reason]}</strong>"
              note += "<br>#{p[:notes]}" unless p[:notes].blank?
              notes << note
              text += " <sup><strong><color rgb=\"000000\">#{notes.length - 1}</color></strong></sup>"
              # self.txtb("#{Time.parse(p[:timestamp]).strftime("%a %m/%d %I:%M %P")} – #{p[:type].titleize} <sup><strong><color rgb=\"000000\">#{notes.length - 1}</color></strong></sup>", x, y, 2.25, line_height, size: 7.5, h_align: :left, h_pad: 0.05, v_align: :center)
            #else
              #self.txtb("#{Time.parse(p[:timestamp]).strftime("%a %m/%d %I:%M %P")} – #{p[:type].titleize}", x, y, 2.25, line_height, size: 7.5, h_align: :left, h_pad: 0.05, v_align: :center)
            end
            self.txtb(text, x, y, 2.25, line_height, size: 7.5, h_align: :left, h_pad: 0.05, v_align: :center)
            y -= line_height
          end
        end

        # Set x and y coordinates for notes box.
        x = ((col) * 4.25) + 0.25
        y = 10.75

        # Draw notes.
        if notes.length == 0
          notes << "<u><strong><font size=\"10\">NOTES</font></strong></u>"
          notes << "<color rgb=\"555555\"><i>No notes entered.</i></color>"
        end
        notes_box_height = y - 0.25
        self.txtb(notes.join('<br><br>'), x, y, 3.75, notes_box_height, h_align: :left, v_align: :top, size: 8)

      end

      # Move to next column for next employee.
      col += 1

    end

  end

end