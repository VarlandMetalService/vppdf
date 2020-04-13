# Class for printing purchase order from System i.
class PurchaseOrder < VarlandPdf

  # Landscape orientation.
  PAGE_ORIENTATION = :portrait
  
  # Constructor.
  def initialize(po_number)

    # Call parent constructor.
    super()

    # Load data.
    @po_number = po_number
    self.load_data

    # Draw data.
    self.draw_data

    # Number pages.
    if self.page_count > 1
      string = "Page <page> of <total>"
      options = {at: [5.75.in, 9.25.in],
                width: 2.5.in,
                height: 0.25.in,
                align: :right,
                size: 8,
                start_count_at: 1,
                valign: :center,
                inline_format: true}
      self.number_pages(string, options)
    end

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://as400railsapi.varland.com/v1/po?po=#{@po_number}")
  end

  def calc_item_lines(item)
    return [1, item[:remarks].length].max
  end

  # Draw data.
  def draw_data

    # Set line height.
    line_height = 0.2

    # Set vertical position.
    y = 8.75
    lines_remaining = 8.25 / line_height

    # Print each item.
    @data[:items].each do |item|

      # Calculate lines for item.
      lines = self.calc_item_lines(item)
      if lines > lines_remaining
        self.start_new_page
        y = 8.75
        lines_remaining = 8.25 / line_height
      end

      # Print item.
      remarks_y = y
      self.txtb(item[:account], 0.25, y, 0.75, line_height, font: "SF Mono", size: 9)
      self.txtb("#{self.format_number(item[:quantity], decimals: 2, strip_insignificant_zeros: true)} #{item[:unit]}", 5, y, 1, line_height, h_align: :right, h_pad: 0.1, font: "SF Mono", size: 9)
      self.txtb("$#{self.format_number(item[:price], decimals: 4, strip_insignificant_zeros: true, min_decimals: 2)}/#{item[:unit]}", 6, y, 1.25, line_height, h_align: :right, h_pad: 0.1, font: "SF Mono", size: 9)
      self.txtb("$", 7.25, y, 1, line_height, h_align: :left, h_pad: 0.1, font: "SF Mono", size: 9)
      self.txtb(self.format_number(item[:total], decimals: 2), 7.25, y, 1, line_height, h_align: :right, h_pad: 0.1, font: "SF Mono", size: 9)
      y -= line_height

      # Print description.
      item[:remarks].each do |r|
        self.txtb(r, 1, remarks_y, 4, line_height, h_align: :left, h_pad: 0.1, font: "SF Mono", size: 9, transform: :nbsp)
        remarks_y -= line_height
      end

      # Set y.
      y = [y, remarks_y].min

      # If not at bottom, print blank line.
      y -= line_height unless y == 0.5

      # Decrease lines remaining.
      lines_remaining -= lines + 1
      
    end

    # Print header and footer on all pages.
    self.repeat(:all) do

      # Draw logo.
      self.logo(0.25, 10.75, 4, 1.25, variant: :stacked, mono: true, h_align: :left)

      # Draw PO number.
      self.txtb("PO ##{@data[:purchase_order]}",
                4.25,
                10.75,
                4,
                0.5,
                size: 24,
                style: :bold,
                fill_color: '000000',
                color: 'ffffff',
                line_color: '000000')

      # Draw PO details.
      self.txtb("Vendor", 4.25, 10.25, 1, 0.25, fill_color: "e3e3e3", line_color: "000000", size: 8, style: :bold, transform: :uppercase)
      self.txtb("By", 4.25, 10, 1, 0.25, fill_color: "e3e3e3", line_color: "000000", size: 8, style: :bold, transform: :uppercase)
      self.txtb("FOB", 5.25, 10, 1, 0.25, fill_color: "e3e3e3", line_color: "000000", size: 8, style: :bold, transform: :uppercase)
      self.txtb("Ordered", 6.25, 10, 1, 0.25, fill_color: "e3e3e3", line_color: "000000", size: 8, style: :bold, transform: :uppercase)
      self.txtb("Delivery", 7.25, 10, 1, 0.25, fill_color: "e3e3e3", line_color: "000000", size: 8, style: :bold, transform: :uppercase)
      self.txtb("#{@data[:vendor][:code]} – #{@data[:vendor][:name][0]}", 5.25, 10.25, 3, 0.25, line_color: "000000", size: 10, style: :bold, transform: :uppercase)
      self.txtb(@data[:approved_by], 4.25, 9.75, 1, 0.25, line_color: "000000", size: 10, style: :bold, transform: :uppercase)
      self.txtb(@data[:fob], 5.25, 9.75, 1, 0.25, line_color: "000000", size: 10, style: :bold, transform: :uppercase)
      self.txtb(Time.iso8601(@data[:order_date]).strftime("%m/%d/%y"), 6.25, 9.75, 1, 0.25, line_color: "000000", size: 10, style: :bold, transform: :uppercase)
      self.txtb(Time.iso8601(@data[:due_date]).strftime("%m/%d/%y"), 7.25, 9.75, 1, 0.25, line_color: "000000", size: 10, style: :bold, transform: :uppercase)

      # Draw confirmation box if necessary.
      # if @data[:confirming]
      #   self.txtb("CONFIRMATION – DO NOT DUPLICATE", 0.25, 0.5, 5.75, 0.25, line_color: "000000", fill_color: "000000", color: "ffffff", size: 10, style: :bold)
      # end
      
      # Draw grand total.
      self.txtb("Grand Total", 6, 0.5, 1.25, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("$", 7.25, 0.5, 1, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold, h_align: :left, h_pad: 0.1)
      self.txtb(self.format_number(@data[:grand_total], decimals: 2), 7.25, 0.5, 1, 0.25, size: 10, style: :bold, h_align: :right, h_pad: 0.1)
      
      # Draw table.
      self.txtb("Account #", 0.25, 9, 0.75, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("Description", 1, 9, 4, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold, h_align: :left, h_pad: 0.1)
      self.txtb("Quantity", 5, 9, 1, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("Unit Price", 6, 9, 1.25, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("Total", 7.25, 9, 1, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.rect(0.25, 8.75, 0.75, 8.25)
      self.rect(1, 8.75, 4, 8.25)
      self.rect(5, 8.75, 1, 8.25)
      self.rect(6, 8.75, 1.25, 8.25)
      self.rect(7.25, 8.75, 1, 8.25)

    end

  end

end