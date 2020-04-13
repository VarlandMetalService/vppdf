# Class for printing inventory worksheet.
class InventoryWorksheet < VarlandPdf

  # Landscape orientation.
  PAGE_ORIENTATION = :landscape

  # Constructor.
  def initialize(account)

    # Call parent constructor.
    super()

    # Load JSON data.
    @account = account
    @description = nil
    self.load_data

    # Call function to draw format.
    self.draw_format

    # Add page numbers.
    string = "Page <page> of <total>"
    options = {at: [0.25.in, 8.25.in],
              width: 10.5.in,
              height: 0.5.in,
              align: :right,
              size: 10,
              start_count_at: 1,
              valign: :center,
              inline_format: true}
    self.number_pages(string, options)

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://as400api.varland.com/v1/physical_inventory")
  end

  # Function to draw format.
  def draw_format

    # Sample table.
    table = DataTable.new(x: 0.25,
                          y: 7.2,
                          width: 10.5,
                          height: 6.5625,
                          column_widths: [6, 0.5, 1, 1, 1, 1],
                          headers: ['Material', 'Unit', 'Previous EOM Quantity', 'Current Month Usage', 'Book Quantity', 'Physical Quantity'],
                          headers_h_align: [:left, :center, :center, :center, :center, :center],
                          header_height: 0.75,
                          header_bg_color: "222222",
                          header_font_color: "ffffff",
                          rows_h_align: [:left, :center, :right, :right, :right, :right],
                          row_bg_colors: ['e3e3e3', 'ffffff'],
                          row_height: 0.3875,
                          data_font_size: 9,
                          data_font: 'SF Mono')
    @data.each do |row|
      next unless row[:account] == @account
      @description = row[:account_description][0] if @description.blank?
      desc = "<b>#{row[:material].ljust(8, ' ')}</b> – #{row[:description][0]}"
      if row[:description][1].blank?
        desc += "\n "
      else
        desc += "\n<b>" + (" " * 8) + "</b>" + (" " * 3) + row[:description][1]
      end
      table.rows << [
        desc,
        row[:unit],
        self.format_number(row[:eom_quantity], decimals: 2),
        row[:usage] == 0 ? nil : self.format_number(row[:usage], decimals: 2),
        self.format_number(row[:book_quantity], decimals: 2)
      ]
    end
    table.draw(self)

    # Header on each page.
    self.repeat(:all) do

      # Loog.
      self.logo(0.25, 8.25, 0.5, 0.5, variant: :mark, h_align: :center, v_align: :center, mono: true)

      # Draw title.
      self.txtb("Book Inventory\nWorksheet",
                0.8,
                8.25,
                4,
                0.5,
                size: 24,
                style: :bold,
                h_align: :left,
                transform: :uppercase,
                v_pad: 0.05)
      
      # Draw account number and name.
      self.txtb("Account #: <b>#{@account} #{@description}</b>", 0.25, 7.5, 10.5, 0.3, h_align: :left, size: 14)
      self.txtb("Month: <b>#{Date.parse(@data[0][:date]).strftime("%B %Y")}</b>", 0.25, 7.5, 10.5, 0.3, h_align: :right, size: 14)

      # Draw date/time printed.
      self.txtb("Printed: <b>#{Time.now.strftime("%m/%d/%y %I:%M %P")}</b>", 0.25, 0.5, 10.5, 0.25, h_align: :right, size: 10)

    end

  end

end