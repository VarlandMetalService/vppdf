# Class for printing purchase order from System i.
class PurchaseOrderLandscape < VarlandPdf

  # Landscape orientation.
  PAGE_ORIENTATION = :landscape

  # Use letterhead.
  LETTERHEAD_FORMAT = :landscape_mono
  
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
      options = {at: [8.25.in, 5.5.in],
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
    y = 5
    lines_remaining = 4.5 / line_height

    # Print each item.
    @data[:items].each do |item|

      # Calculate lines for item.
      lines = self.calc_item_lines(item)
      if lines > lines_remaining
        self.start_new_page
        y = 5
        lines_remaining = 4.5 / line_height
      end

      # Print item.
      remarks_y = y
      self.txtb(item[:account], 0.25, y, 1, line_height, font: "SF Mono", size: 10)
      self.txtb("#{self.format_number(item[:quantity], decimals: 2, strip_insignificant_zeros: true)} #{item[:unit]}", 7, y, 1.25, line_height, h_align: :right, h_pad: 0.1, font: "SF Mono", size: 10)
      self.txtb("$#{self.format_number(item[:price], decimals: 4, strip_insignificant_zeros: true, min_decimals: 2)}/#{item[:unit]}", 8.25, y, 1.25, line_height, h_align: :right, h_pad: 0.1, font: "SF Mono", size: 10)
      self.txtb("$", 9.5, y, 1.25, line_height, h_align: :left, h_pad: 0.1, font: "SF Mono", size: 10)
      self.txtb(self.format_number(item[:total], decimals: 2), 9.5, y, 1.25, line_height, h_align: :right, h_pad: 0.1, font: "SF Mono", size: 10)
      y -= line_height

      # Print description.
      item[:remarks].each do |r|
        self.txtb(r, 1.25, remarks_y, 5.75, line_height, h_align: :left, h_pad: 0.1, font: "SF Mono", size: 10, transform: :nbsp)
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

      # Draw quote number.
      self.txtb("PO ##{@data[:purchase_order]}",
                0.25,
                6.9,
                10.5,
                0.25,
                size: 24,
                style: :bold)

      # Draw vendor information.
      self.txtb("Purchased From:\n<b>#{@data[:vendor][:code]}\n#{@data[:vendor][:name].join("\n")}\n#{@data[:vendor][:address]}\n#{@data[:vendor][:city]}, #{@data[:vendor][:state]} #{@data[:vendor][:zip]}</b>",
                0.25,
                6.5,
                4,
                1,
                size: 10,
                h_align: :left,
                v_align: :top,
                v_pad: 0.05)

      # Draw approval information.
      self.txtb("Purchased/Approved By:\n<b>#{@data[:approved_by]}</b>",
                4.25,
                6.5,
                4,
                1,
                size: 10,
                h_align: :left,
                v_align: :top,
                v_pad: 0.05)

      # Draw order and delivery information.
      self.txtb("Order Date: <b>#{Time.iso8601(@data[:order_date]).strftime("%m/%d/%y")}</b>\nDelivery Date: <b>#{Time.iso8601(@data[:due_date]).strftime("%m/%d/%y")}</b>\n\nFOB: <b>#{@data[:fob]}</b>",
                8.25,
                6.5,
                2.5,
                1,
                size: 10,
                h_align: :left,
                v_align: :top,
                v_pad: 0.05)

      # Draw confirmation box if necessary.
      if @data[:confirming]
        self.txtb("CONFIRMATION – DO NOT DUPLICATE", 0.25, 0.5, 8, 0.25, line_color: "000000", fill_color: "000000", color: "ffffff", size: 10, style: :bold)
      end
      
      # Draw grand total.
      self.txtb("Grand Total", 8.25, 0.5, 1.25, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("$", 9.5, 0.5, 1.25, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold, h_align: :left, h_pad: 0.1)
      self.txtb(self.format_number(@data[:grand_total], decimals: 2), 9.5, 0.5, 1.25, 0.25, size: 10, style: :bold, h_align: :right, h_pad: 0.1)
      
      # Draw table.
      self.txtb("Account #", 0.25, 5.25, 1, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("Description", 1.25, 5.25, 5.75, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold, h_align: :left, h_pad: 0.1)
      self.txtb("Quantity", 7, 5.25, 1.25, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("Unit Price", 8.25, 5.25, 1.25, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.txtb("Total", 9.5, 5.25, 1.25, 0.25, line_color: "000000", fill_color: "e3e3e3", size: 10, style: :bold)
      self.rect(0.25, 5, 1, 4.5)
      self.rect(1.25, 5, 5.75, 4.5)
      self.rect(7, 5, 1.25, 4.5)
      self.rect(8.25, 5, 1.25, 4.5)
      self.rect(9.5, 5, 1.25, 4.5)

    end

  end

end