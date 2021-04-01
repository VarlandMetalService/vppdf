# Class for printing EN report from System i.
class EnReport < VarlandPdf

  # Landscape orientation.
  PAGE_ORIENTATION = :landscape
  
  # Constructor.
  def initialize(year, month, day)

    # Call parent constructor.
    super()

    # Load data.
    @year = year
    @month = month
    @day = day
    unless @year && @month && @day
      @year = Date.yesterday.year
      @month = Date.yesterday.month
      @day = Date.yesterday.day
    end
    self.load_data

    # Print data.
    self.draw_data

    # Number pages.
    if self.page_count > 1
      string = "<i>Page <page> of <total></i>"
      options = {at: [5.in, 8.25.in],
                width: 2.5.in,
                height: 0.5.in,
                align: :center,
                size: 14,
                start_count_at: 1,
                valign: :center,
                inline_format: true}
      self.number_pages(string, options)
    end

  end

  def title
    return "EN Additions for #{Time.iso8601(@data[:date]).strftime("%m.%d.%y")}"
  end

  # Loads json data.
  def load_data
    if @year && @month && @day
      @data = self.load_json("http://json400.varland.com/daily_en_materials?year=#{@year}&month=#{@month}&day=#{@day}")
    else
      @data = self.load_json("http://json400.varland.com/daily_en_materials")
    end
  end

  # Prints data.
  def draw_data

    # Format report date.
    report_date = Time.iso8601(@data[:date]).strftime("%m/%d/%y")

    # Initialize y position @ report characteristics.
    y = 7.5
    drew_en_header = false
    drew_hp_header = false

    # Draw header for mid-phos EN.
    self.txtb("Mid-Phos EN".upcase, 0.25, y, 10.5, 0.2, h_align: :left, size: 12, style: :bold)
    y -= 0.25

    # Print mid-phos data.
    if @data[:en][:lines].length == 0
      self.txtb("<i>No production recorded on #{report_date}.</i>", 0.25, y, 10.5, 0.2, h_align: :left)
      y -= 0.2
    else
      en_totals = []
      @data[:en][:lines].each do |line|
        if y < 1
          self.start_new_page
          drew_en_header = false
          y = 7.5
          self.txtb("Mid-Phos EN", 0.25, y, 10.5, 0.2, h_align: :left, size: 12, style: :bold)
          y -= 0.25
        end
        unless drew_en_header
          self.txtb("CUSTOMER", 0.25, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :left, h_pad: 0.05, line_color: "000000")
          self.txtb("PART ID", 1.25, y, 1.5, 0.5, fill_color: "cccccc", style: :bold, h_align: :left, h_pad: 0.05, line_color: "000000")
          self.txtb("SUB", 2.75, y, 0.5, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("LBS × FT²/LB ×\nPLATING TIME", 3.25, y, 1.25, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("LBS", 4.5, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("FT²/LB", 5.5, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("MINUTES", 6.5, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          count_adds = line[:adds].length
          add_width = (10.75 - 7.5) / count_adds.to_f
          x = 7.5
          line[:adds].each do |add|
            self.txtb("#{add[:material]}\n(#{add[:unit]})", x, y, add_width, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
            en_totals << 0
            x += add_width
          end
          drew_en_header = true
          y -= 0.5
        end
        self.txtb(line[:customerCode], 0.25, y, 1, 0.25, h_align: :left, h_pad: 0.05, line_color: "000000")
        self.txtb(line[:partID], 1.25, y, 1.5, 0.25, h_align: :left, h_pad: 0.05, line_color: "000000")
        self.txtb(line[:subID], 2.75, y, 0.5, 0.25, print_blank: true, h_align: :center, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:squareFeetMinutes], decimals: 2), 3.25, y, 1.25, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:pounds], decimals: 2), 4.5, y, 1, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:squareFeetPerPound], decimals: 2), 5.5, y, 1, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:minutes], decimals: 0), 6.5, y, 1, 0.25, h_align: :center, h_pad: 0.05, line_color: "000000")
        count_adds = line[:adds].length
        add_width = (10.75 - 7.5) / count_adds.to_f
        x = 7.5
        line[:adds].each_with_index { |add,index|
          self.txtb(self.format_number(add[:amount], decimals: 2), x, y, add_width, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
          en_totals[index] += add[:amount]
          x += add_width
        }
        y -= 0.25
      end
      x = 7.5
      add_width = (10.75 - 7.5) / en_totals.length.to_f
      en_totals.each do |total|
        self.txtb(self.format_number(total, decimals: 2), x, y, add_width, 0.25, fill_color: "eeeeee", style: :bold, h_align: :right, h_pad: 0.05, line_color: "000000")
        x += add_width
      end
      y -= 0.25
    end

    # Move down to leave space between types.
    y -= 0.25

    # Start new page if too far down page.
    if y < 2
      self.start_new_page
      y = 7.5
    end

    # Draw header for hi-phos EN.
    self.txtb("Hi-Phos EN".upcase, 0.25, y, 10.5, 0.2, h_align: :left, size: 12, style: :bold)
    y -= 0.25

    # Print hi-phos data.
    if @data[:hp][:lines].length == 0
      self.txtb("<i>No production recorded on #{report_date}.</i>", 0.25, y, 10.5, 0.2, h_align: :left)
      y -= 0.2
    else
      hp_totals = []
      @data[:hp][:lines].each do |line|
        if y < 1
          self.start_new_page
          drew_hp_header = false
          y = 7.5
          self.txtb("Hi-Phos EN", 0.25, y, 10.5, 0.2, h_align: :left, size: 12, style: :bold)
          y -= 0.25
        end
        unless drew_hp_header
          self.txtb("CUSTOMER", 0.25, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :left, h_pad: 0.05, line_color: "000000")
          self.txtb("PART ID", 1.25, y, 1.5, 0.5, fill_color: "cccccc", style: :bold, h_align: :left, h_pad: 0.05, line_color: "000000")
          self.txtb("SUB", 2.75, y, 0.5, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("LBS × FT²/LB ×\nPLATING TIME", 3.25, y, 1.25, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("LBS", 4.5, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("FT²/LB", 5.5, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          self.txtb("MINUTES", 6.5, y, 1, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
          count_adds = line[:adds].length
          add_width = (10.75 - 7.5) / count_adds.to_f
          x = 7.5
          line[:adds].each do |add|
            self.txtb("#{add[:material]}\n(#{add[:unit]})", x, y, add_width, 0.5, fill_color: "cccccc", style: :bold, h_align: :center, h_pad: 0.05, line_color: "000000")
            hp_totals << 0
            x += add_width
          end
          drew_hp_header = true
          y -= 0.5
        end
        self.txtb(line[:customerCode], 0.25, y, 1, 0.25, h_align: :left, h_pad: 0.05, line_color: "000000")
        self.txtb(line[:partID], 1.25, y, 1.5, 0.25, h_align: :left, h_pad: 0.05, line_color: "000000")
        self.txtb(line[:subID], 2.75, y, 0.5, 0.25, print_blank: true, h_align: :center, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:squareFeetMinutes], decimals: 2), 3.25, y, 1.25, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:pounds], decimals: 2), 4.5, y, 1, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:squareFeetPerPound], decimals: 2), 5.5, y, 1, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
        self.txtb(self.format_number(line[:minutes], decimals: 0), 6.5, y, 1, 0.25, h_align: :center, h_pad: 0.05, line_color: "000000")
        count_adds = line[:adds].length
        add_width = (10.75 - 7.5) / count_adds.to_f
        x = 7.5
        line[:adds].each_with_index { |add,index|
          self.txtb(self.format_number(add[:amount], decimals: 2), x, y, add_width, 0.25, h_align: :right, h_pad: 0.05, line_color: "000000")
          hp_totals[index] += add[:amount]
          x += add_width
        }
        y -= 0.25
      end
      x = 7.5
      add_width = (10.75 - 7.5) / en_totals.length.to_f
      en_totals.each do |total|
        self.txtb(self.format_number(total, decimals: 2), x, y, add_width, 0.25, fill_color: "eeeeee", style: :bold, h_align: :right, h_pad: 0.05, line_color: "000000")
        x += add_width
      end
      y -= 0.25
    end

    # Print header and footer on all pages.
    self.repeat(:all) do

      # Draw title & logo.
      self.logo(0.25, 8.25, 10.5, 0.5, variant: :stacked, mono: true, h_align: :right)
      self.txtb("EN Additions for #{report_date}".upcase, 0.25, 8.25, 10.5, 0.5, h_align: :left, style: :bold, size: 14)

    end

  end

end