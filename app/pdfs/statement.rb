# Class for printing statement from System i.
class Statement < VarlandPdf

  # Use letterhead.
  LETTERHEAD_FORMAT = :landscape
  PAGE_ORIENTATION = :landscape
  
  # Constructor.
  def initialize(customer = nil)

    # Call parent constructor.
    super()
    
    # Store customer code.
    @customer = customer
    self.load_data

    # Draw format.
    self.draw_format

    # Draw data.
    self.draw_data

    # Number pages.
    string = "<b>Page <page> of <total></b>"
    options = {at: [0.25.in, 0.5.in],
               width: 10.5.in,
               height: 0.25.in,
               align: :center,
               size: 8,
               start_count_at: 1,
               valign: :center,
               inline_format: true}
    self.number_pages(string, options)

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://json400.varland.com/statement?customer=#{@customer}")
  end

  # Draws data.
  def draw_data
    
    # Initialize.
    lines_per_page = 24
    lines_remaining = lines_per_page
    y = 5.5
    default_options = {size: 9, h_pad: 0.05}

    # Draw each invoice.
    @data[:invoices].each do |invoice|

      # Calculate lines for invoice.
      invoice[:purchase_orders].delete ""
      lines_required = [invoice[:purchase_orders].length, invoice[:setup_charge] > 0 ? 2 : 1].max

      # Move to next page if necessary.
      if lines_required > lines_remaining
        self.start_new_page
        self.draw_format
        lines_remaining = lines_per_page
        y = 5.5
      end

      # Draw boxes.
      self.rect(0.25, y, 1, 0.2 * lines_required)
      self.rect(1.25, y, 1, 0.2 * lines_required)
      self.rect(2.25, y, 1, 0.2 * lines_required)
      self.rect(3.25, y, 2.5, 0.2 * lines_required)
      self.rect(5.75, y, 2.5, 0.2 * lines_required)
      self.rect(8.25, y, 1.25, 0.2 * lines_required)
      self.rect(9.5, y, 1.25, 0.2 * lines_required)

      # Draw invoice details.
      self.txtb(invoice[:number], 0.25, y, 1, 0.2, default_options)
      self.txtb(Time.iso8601(invoice[:date]).strftime("%m/%d/%y"), 1.25, y, 1, 0.2, default_options)
      self.txtb(invoice[:shop_order], 2.25, y, 1, 0.2, default_options)
      self.txtb("#{invoice[:process_code]}   #{invoice[:part_id]}   #{invoice[:sub_id]}", 3.25, y, 2.5, 0.2, default_options.merge(h_align: :left))
      temp_y = y
      invoice[:purchase_orders].each do |po|
        self.txtb(po, 5.75, temp_y, 2.5, 0.2, default_options.merge(h_align: :left))
        temp_y -= 0.2
      end
      self.txtb("$#{self.format_number(invoice[:unit_price], decimals: 4, strip_insignificant_zeros: true)}/#{invoice[:price_per]}", 8.25, y, 1.25, 0.2, default_options)
      if invoice[:setup_charge] > 0
        self.txtb("Setup: $#{self.format_number(invoice[:setup_charge], decimals: 2)}", 8.25, y - 0.2, 1.25, 0.2, default_options)
      end
      self.txtb("$#{self.format_number(invoice[:invoice_total], decimals: 2)}", 9.5, y, 1.25, 0.2, default_options.merge(h_align: :right))

      # Update y position and lines remaining.
      y -= 0.2 * lines_required
      lines_remaining -= lines_required

    end

  end

  # Draws format.
  def draw_format

    # Draw address and header lines.
    address = [@data[:customer][:name][0],
               @data[:customer][:name][1],
               @data[:customer][:address],
               "#{@data[:customer][:city]}, #{@data[:customer][:state]} #{@data[:customer][:zip]}"]
    address.delete ""
    self.txtb(address.join("\n"), 0.25, 6.75, 5.25, 0.6, h_align: :left, style: :bold)
    self.txtb("#{@data[:summary][:count]} Open Invoice#{@data[:summary][:count] == 1 ? "" : "s"}", 5.5, 6.75, 5.25, 0.3, h_align: :right, style: :bold)
    self.txtb("Balance: $#{self.format_number(@data[:summary][:total], decimals: 2, min_decimals: 2)}", 5.5, 6.45, 5.25, 0.3, h_align: :right, style: :bold)

    # Draw table.
    self.txtb("Invoice #", 0.25, 5.9, 1, 0.4, fill_color: "eeeeee", line_color: "000000", style: :bold)
    self.txtb("Date", 1.25, 5.9, 1, 0.4, fill_color: "eeeeee", line_color: "000000", style: :bold)
    self.txtb("Varland\nOrder #", 2.25, 5.9, 1, 0.4, fill_color: "eeeeee", line_color: "000000", style: :bold)
    self.txtb("Part", 3.25, 5.9, 2.5, 0.4, fill_color: "eeeeee", line_color: "000000", style: :bold, h_pad: 0.05, h_align: :left)
    self.txtb("Purchase Order #", 5.75, 5.9, 2.5, 0.4, fill_color: "eeeeee", line_color: "000000", style: :bold, h_pad: 0.05, h_align: :left)
    self.txtb("Price", 8.25, 5.9, 1.25, 0.4, fill_color: "eeeeee", line_color: "000000", style: :bold)
    self.txtb("Total", 9.5, 5.9, 1.25, 0.4, fill_color: "eeeeee", line_color: "000000", style: :bold)
    #self.rect(0.25, 5.5, 1, 4.8)
    #self.rect(1.25, 5.5, 1, 4.8)
    #self.rect(2.25, 5.5, 1, 4.8)
    #self.rect(3.25, 5.5, 2.5, 4.8)
    #self.rect(5.75, 5.5, 2.5, 4.8)
    #self.rect(8.25, 5.5, 1.25, 4.8)
    #self.rect(9.5, 5.5, 1.25, 4.8)

  end

end