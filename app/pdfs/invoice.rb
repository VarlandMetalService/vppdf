# Class for printing invoice from System i.
class Invoice < VarlandPdf

  # Use letterhead.
  LETTERHEAD_FORMAT = :portrait
  
  # Constructor.
  def initialize(invoice = nil, source = nil)

    # Call parent constructor.
    super()

    # Store invoice properties.
    @widths = [0.85, 0.65, 0.65, 2.25, 1.25, 1.35, 1]
    @table_height = 6.75
    @line_height = 0.15

    # Load data.
    if invoice.blank?
      self.load_sample_data
    else
      @invoice = invoice
      @source = source
      self.load_data
    end

    # Calculate pages needed.
    @orders = []
    @data[:orders].each do |order| @orders << InvoiceOrder.new(order) end

    # Format page.
    self.draw_format

    # Print data.
    self.draw_data

    # Number pages.
    string = "<b>PAGE: <page> OF <total></b>"
    options = {at: [6.in, 9.4.in],
               width: 2.25.in,
               height: 0.25.in,
               align: :right,
               size: 8,
               start_count_at: 1,
               valign: :center,
               inline_format: true}
    self.number_pages(string, options)

  end
  
  # Loads sample data.
  def load_sample_data
    @data = self.load_sample("invoice")
  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://as400railsapi.varland.com/v1/invoice?invoice=#{@invoice}")
  end

  # Prints data.
  def draw_data

    # Format dates.
    invoice_date = Time.iso8601(@data[:invoice_date]).strftime("%m/%d/%y")

    # Print orders.
    lines_per_page = (@table_height / @line_height).to_i
    lines_remaining = lines_per_page
    y = 7.5
    grand_total = 0
    default_options = {size: 8, h_pad: 0.05}
    special_options = {size: 6, style: :bold, h_pad: 0.05}
    @orders.each do |order|

      # Accumulate total.
      grand_total += order.total

      # Move to next page if necessary.
      if order.lines_required > lines_remaining
        self.start_new_page
        self.draw_format
        lines_remaining = lines_per_page
        y = 7.5
      end

      # Print order details.
      lines_printed = 0
      if order.shipper
        lines_printed = 2
        self.txtb("SHIPPER #:",
                  0.25,
                  y,
                  @widths[0],
                  @line_height,
                  special_options)
        self.txtb(order.shipper,
                  0.25,
                  y - @line_height,
                  @widths[0],
                  @line_height,
                  default_options)
      end
      if order.shop_order
        self.txtb("VMS ORDER #:",
                  0.25,
                  y - lines_printed * @line_height,
                  @widths[0],
                  @line_height,
                  special_options)
        self.txtb(order.shop_order,
                  0.25,
                  y - (lines_printed + 1) * @line_height,
                  @widths[0],
                  @line_height,
                  default_options)
        lines_printed += 2
      end
      if order.ship_date
        self.txtb("SHIP DATE:",
                  0.25,
                  y - lines_printed * @line_height,
                  @widths[0],
                  @line_height,
                  special_options)
        self.txtb(order.ship_date,
                  0.25,
                  y - (lines_printed + 1) * @line_height,
                  @widths[0],
                  @line_height,
                  default_options)
      end
      if order.pounds != 0
        self.txtb(self.format_number(order.pounds, decimals: 2),
                  0.25 + @widths[0],
                  y,
                  @widths[1],
                  @line_height,
                  default_options)
      end
      if !order.is_complete && order.pounds_remaining != 0
        self.rect(0.25 + @widths[0] + 0.05,
                  y - 1.25 * @line_height,
                  @widths[1] - 0.1,
                  2.5 * @line_height,
                  fill_color: "e3e3e3")
        self.txtb("BALANCE:",
                  0.25 + @widths[0],
                  y - 1.5 * @line_height,
                  @widths[1],
                  @line_height,
                  default_options.except(:h_pad, :size).merge(h_pad: 0.1, size: 6))
        self.txtb(self.format_number(order.pounds_remaining, decimals: 2),
                  0.25 + @widths[0],
                  y - 2.5 * @line_height,
                  @widths[1],
                  @line_height,
                  default_options.except(:h_pad, :size).merge(h_pad: 0.1, size: 6))
      end
      if order.pieces != 0
        self.txtb(self.format_number(order.pieces),
                  0.25 + @widths[0..1].sum,
                  y,
                  @widths[2],
                  @line_height,
                  default_options)
      end
      if !order.is_complete && order.pieces_remaining != 0
        self.rect(0.25 + @widths[0..1].sum + 0.05,
                  y - 1.25 * @line_height,
                  @widths[2] - 0.1,
                  2.5 * @line_height,
                  fill_color: "e3e3e3")
        self.txtb("BALANCE:",
                  0.25 + @widths[0..1].sum,
                  y - 1.5 * @line_height,
                  @widths[2],
                  @line_height,
                  default_options.except(:h_pad, :size).merge(h_pad: 0.1, size: 6))
        self.txtb(self.format_number(order.pieces_remaining, decimals: 2),
                  0.25 + @widths[0..1].sum,
                  y - 2.5 * @line_height,
                  @widths[2],
                  @line_height,
                  default_options.except(:h_pad, :size).merge(h_pad: 0.1, size: 6))
      end
      lines_printed = 0
      unless order.part_id.blank? && order.sub_id.blank? && order.process_code.blank?
        lines_printed = 1
        self.txtb("#{order.part_id} #{order.sub_id}",
                  0.25 + @widths[0..2].sum,
                  y,
                  @widths[3],
                  @line_height,
                  default_options.merge(h_align: :left))
        self.txtb(order.process_code,
                  0.25 + @widths[0..2].sum,
                  y,
                  @widths[3],
                  @line_height,
                  default_options.merge(h_align: :right))
      end
      (order.part_name + order.process_specification).each_with_index do |line, index|
        self.txtb(line,
                  0.25 + @widths[0..2].sum,
                  y - (index + lines_printed) * @line_height,
                  @widths[3],
                  @line_height,
                  default_options.merge(h_align: :left))
      end
      lines_printed = 0
      unless order.miscellaneous_invoice
        lines_printed = 1
        self.txtb((order.is_complete ? "COMPLETE ORDER" : "PARTIAL ORDER"),
                  0.25 + @widths[0..3].sum,
                  y,
                  @widths[4],
                  @line_height,
                  default_options)
      end
      order.purchase_orders.each_with_index do |line, index|
        self.txtb(line,
                  0.25 + @widths[0..3].sum,
                  y - (index + lines_printed) * @line_height,
                  @widths[4],
                  @line_height,
                  default_options)
      end
      order.pricing_labels.each_with_index do |label, index|
        self.txtb(label,
                  0.25 + @widths[0..4].sum,
                  y - index * @line_height,
                  @widths[5],
                  @line_height,
                  default_options.merge(h_align: :left))
        options = (index == order.pricing_labels.length - 1 ? default_options.merge(line: :above) : default_options)
        self.acctb(order.pricing_amounts[index],
                   0.25 + @widths[0..5].sum,
                   y - index * @line_height,
                   @widths[6],
                   @line_height,
                   options)
      end
      # unless (order.remarks.length == 0)
      #   remarks_y = y - (@line_height * (order.lines_required - order.remarks.length))
      #   label_width = self.calc_width("REMARKS: ", style: :normal, size: 8)
      #   self.rect(0.3,
      #             remarks_y + 0.05,
      #             7.9,
      #             0.1 + (@line_height * order.remarks.length),
      #             fill_color: "e3e3e3")
      #   self.txtb("REMARKS: ",
      #             0.35,
      #             remarks_y,
      #             label_width,
      #             @line_height,
      #             size: 8)
      #   order.remarks.each_with_index do |line, index|
      #     self.txtb(line,
      #               0.35 + label_width,
      #               remarks_y - index * @line_height,
      #               6.5,
      #               @line_height,
      #               size: 8,
      #               style: :bold,
      #               h_align: :left)
      #   end
      # end
      y -= @line_height * (order.lines_required + 2)

      # Decrease lines remaining.
      lines_remaining -= (order.lines_required + 2)

    end

    # Print header information on each page.
    self.repeat(:all) do

      # Draw invoice number.
      self.txtb("INVOICE #: #{@data[:invoice]}", 0.25, 9.4, 8, 0.25, size: 24, style: :bold)

      # Draw sold to, ship to, code and fax.
      text = @data[:customer][:our_customer_name].blank? ? "" : "#{@data[:customer][:our_customer_name]}\n"
      text << "#{@data[:customer][:name].join("\n")}\n#{@data[:customer][:street]}\n#{@data[:customer][:city]}, #{@data[:customer][:state]} #{@data[:customer][:zip].to_s.rjust(5, '0')}"
      self.txtb(text, 0.25, 8.75, 4, 0.75, size: 9, h_align: :left, transform: :uppercase, v_align: :top, v_pad: 0.05)
      unless @data[:shipping_address][:street].blank?
        self.txtb("#{@data[:shipping_address][:name].join("\n")}\n#{@data[:shipping_address][:street]}\n#{@data[:shipping_address][:city]}, #{@data[:shipping_address][:state]} #{@data[:shipping_address][:zip].to_s.rjust(5, '0')}", 4.25, 8.75, 2.75, 0.75, size: 9, h_align: :left, transform: :uppercase, v_align: :top, v_pad: 0.05)
      end
      text = @data[:customer][:code]
      text << (@data[:customer][:vendor_id].blank? ? "\n" : "\nVENDOR: #{@data[:customer][:vendor_id]}")
      self.txtb(text, 7, 8.75, 1.25, 0.75, size: 9, h_align: :left, transform: :uppercase, v_align: :top, v_pad: 0.05)

      # Print shipped via, invoice date, and secondary invoice number.
      unless @data[:how_shipped][:code].blank?
        ship_method = "#{@data[:how_shipped][:description]} #{@data[:shipping_remarks]}"
        self.txtb("<b>SHIPPED VIA:</b> #{ship_method}", 0.25, 8, 4, 0.25, size: 9, h_align: :left)
      end
      self.txtb("<b>INVOICE DATE:</b> #{invoice_date}", 4.75, 8, 2, 0.25, size: 9, h_align: :left)
      self.txtb("<b>INVOICE #:</b> #{@data[:invoice]}", 6, 8, 2.25, 0.25, size: 9, h_align: :right)

    end

    # Print special content on only last page.
    self.repeat([self.page_count]) do
      self.txtb(@data[:invoice_terms],
                0.25,
                0.75,
                @widths[0..4].sum,
                0.25,
                size: 8,
                style: :bold,
                line_color: "000000")
      self.txtb("INVOICE TOTAL",
                0.25 + @widths[0..4].sum,
                0.75,
                @widths[5],
                0.25,
                size: 8,
                style: :bold,
                h_align: :left,
                h_pad: 0.1,
                line_color: "000000",
                fill_color: "e3e3e3")
      self.acctb(grand_total,
                 0.25 + @widths[0..5].sum,
                 0.75,
                 @widths[6],
                 0.25,
                 size: 8,
                 style: :bold,
                 h_pad: 0.1,
                 line_color: "000000",
                 fill_color: "e3e3e3")
    end

    # Print special content on all pages except the last page.
    self.repeat(lambda {|pg| pg < self.page_count}) do
      self.txtb("********** CONTINUED ON NEXT PAGE. PLEASE PAY TOTAL AMOUNT LISTED ON LAST PAGE. **********",
                0.25,
                0.75,
                @widths.sum,
                0.25,
                size: 8,
                style: :bold,
                line_color: "000000")
    end

  end

  # Prints standard graphics.
  def draw_format

    # Draw sold to and ship to labels.
    self.txtb("SOLD TO:", 0.25, 8.9, 4, 0.15, size: 11, style: :bold, h_align: :left)
    self.txtb("SHIP TO:", 4.25, 8.9, 4, 0.15, size: 11, style: :bold, h_align: :left)

    # Draw table.
    x = 0.25
    headings = ["Order", "Pounds", "Pieces", "Part Desc./Process Spec.", "Ref #", "Price/Remarks", "Totals"]
    headings.each_with_index do |heading, index|
      self.txtb(heading, x, 7.75, @widths[index], 0.25, size: 8, style: :bold, transform: :uppercase, line_color: "000000", fill_color: "e3e3e3")
      self.rect(x, 7.5, @widths[index], @table_height)
      x += @widths[index]
    end

    # Compliance line.
    self.txtb("We Hereby Certify That These Goods Were Produced In Compliance With The Fair Labor Standards Act, As Amended", 0.25, 0.5, 8, 0.25, size: 8, style: :bold)

  end

end