# Class for printing invoice from System i.
class Invoice < VarlandPdf

  # Use letterhead.
  LETTERHEAD_FORMAT = :portrait
  
  # Constructor.
  def initialize(invoice = nil)

    # Call parent constructor.
    super()

    # # Load data.
    # if invoice.blank?
    #   self.load_sample_data
    # else
    #   @invoice = invoice
    #   self.load_data
    # end

    # Add extra pages.
    2.times do self.start_new_page end

    # Store column widths.
    @widths = [1, 0.75, 0.75, 2, 1.25, 1.25, 1]

    # Print data.
    self.draw_data

    # Format pages.
    self.draw_format

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

    self.repeat(:all) do

      # Draw invoice number.
      self.txtb("INVOICE #: 285406", 0.25, 9.4, 8, 0.25, size: 24, style: :bold)

      # Draw sold to, ship to, code and fax.
      self.txtb("name\nname\naddress\nCity, State Zip", 0.25, 8.75, 4, 0.75, size: 9, h_align: :left, transform: :uppercase, v_align: :top, v_pad: 0.05)
      self.txtb("name\nname\naddress\nCity, State Zip", 4.25, 8.75, 2.5, 0.75, size: 9, h_align: :left, transform: :uppercase, v_align: :top, v_pad: 0.05)
      self.txtb("code\nVendor:\nFax", 6.75, 8.75, 1.5, 0.75, size: 9, h_align: :left, transform: :uppercase, v_align: :top, v_pad: 0.05)

      # Print shipped via, invoice date, and secondary invoice number.
      self.txtb("<b>SHIPPED VIA:</b> XXX", 0.25, 8, 4, 0.25, size: 9, h_align: :left)
      self.txtb("<b>INVOICE DATE:</b> mm/dd/yy", 4.75, 8, 2, 0.25, size: 9, h_align: :left)
      self.txtb("<b>INVOICE #:</b> 285406", 6, 8, 2.25, 0.25, size: 9, h_align: :right)

      # Draw data.
      y = 7.5
      row_height = 0.1875
      default_options = {size: 8, h_pad: 0.1}
      special_options = {size: 6, style: :bold, h_pad: 0.1, v_align: :bottom}
      self.txtb("SHIPPER #:", 0.25, y, @widths[0], row_height, special_options)
      self.txtb("0.00", 0.25 + @widths[0], y, @widths[1], row_height, default_options.merge(h_align: :right))
      self.txtb("123", 0.25 + @widths[0..1].sum, y, @widths[2], row_height, default_options.merge(h_align: :right))
      self.txtb("PART ID", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))
      self.txtb("SUB", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :right).except(:fill_color))
      self.txtb("XXX", 0.25 + @widths[0..3].sum, y, @widths[4], row_height, default_options)
      self.txtb("XXX", 0.25 + @widths[0..4].sum, y, @widths[5], row_height, default_options.merge(h_align: :left))
      self.acctb("260", 0.25 + @widths[0..5].sum, y, @widths[6], row_height, default_options)
      y -= row_height
      self.txtb("123456", 0.25, y, @widths[0], row_height, default_options)
      self.txtb("XXX", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))
      self.txtb("XXX", 0.25 + @widths[0..3].sum, y, @widths[4], row_height, default_options)
      self.txtb("XXX", 0.25 + @widths[0..4].sum, y, @widths[5], row_height, default_options.merge(h_align: :left))
      self.acctb(260, 0.25 + @widths[0..5].sum, y, @widths[6], row_height, default_options.merge(line: :above, style: :bold))
      y -= row_height
      self.txtb("VMS ORDER #:", 0.25, y, @widths[0], row_height, special_options)
      self.txtb("XXX", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))
      self.txtb("XXX", 0.25 + @widths[0..3].sum, y, @widths[4], row_height, default_options)
      self.txtb("XXX", 0.25 + @widths[0..4].sum, y, @widths[5], row_height, default_options.merge(h_align: :left))
      y -= row_height
      self.txtb("123456", 0.25, y, @widths[0], row_height, default_options)
      self.txtb("XXX", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))
      self.txtb("XXX", 0.25 + @widths[0..3].sum, y, @widths[4], row_height, default_options)
      self.txtb("XXX", 0.25 + @widths[0..4].sum, y, @widths[5], row_height, default_options.merge(h_align: :left))
      y -= row_height
      self.txtb("SHIP DATE:", 0.25, y, @widths[0], row_height, special_options)
      self.txtb("XXX", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))
      y -= row_height
      self.txtb("123456", 0.25, y, @widths[0], row_height, default_options)
      self.txtb("XXX", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))
      y -= row_height
      self.txtb("XXX", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))
      y -= row_height
      self.txtb("XXX", 0.25 + @widths[0..2].sum, y, @widths[3], row_height, default_options.merge(h_align: :left))

    end

  end

  # Prints standard graphics.
  def draw_format

    # Print special content on only last page.
    self.repeat([self.page_count]) do
      self.rect(0.25 + @widths[0..4].sum, 0.75, @widths[5..6].sum, 0.25, line_color: nil, fill_color: "e3e3e3")
      self.txtb("TERMS: 1% 10 DAYS NET 30, 1 1/2% INTEREST CHARGE ON PAST DUE BALANCE-18% ANNUAL", 0.25, 0.75, @widths[0..4].sum, 0.25, size: 8, style: :bold)
      self.txtb("INVOICE TOTAL", 0.25 + @widths[0..4].sum, 0.75, @widths[5], 0.25, size: 8, style: :bold, h_align: :left, h_pad: 0.1)
      self.vline(0.25 + @widths[0..4].sum, 0.75, 0.25)
      self.vline(0.25 + @widths[0..5].sum, 0.75, 0.25)
    end

    # Print special content on all pages except the last page.
    self.repeat(lambda {|pg| pg < self.page_count}) do
      self.txtb("********** CONTINUED ON NEXT PAGE. PLEASE PAY TOTAL AMOUNT LISTED ON LAST PAGE. **********", 0.25, 0.75, @widths.sum, 0.25, size: 8, style: :bold)
    end

    # Repeat format on all pages.
    self.repeat(:all) do

      # Draw sold to and ship to labels.
      self.txtb("SOLD TO:", 0.25, 8.9, 4, 0.15, size: 11, style: :bold, h_align: :left)
      self.txtb("SHIP TO:", 4.25, 8.9, 4, 0.15, size: 11, style: :bold, h_align: :left)

      # Draw table.
      self.rect(0.25, 7.75, 8, 0.25, fill_color: "e3e3e3", line_color: nil)
      self.rect(0.25, 7.75, 8, 7)
      self.hline(0.25, 7.5, 8)
      self.hline(0.25, 0.5, 8)
      self.vline(0.25, 0.75, 0.25)
      self.vline(8.25, 0.75, 0.25)
      x = 0.25
      headings = ["Order", "Pounds", "Pieces", "Part Desc./Process Spec.", "Ref #", "Price/Remarks", "Totals"]
      headings.each_with_index do |heading, index|
        self.txtb(heading, x, 7.75, @widths[index], 0.25, size: 8, style: :bold, transform: :uppercase)
        self.vline(x, 7.75, 7) if index > 0
        x += @widths[index]
      end

      # Compliance line.
      self.txtb("We Hereby Certify That These Goods Were Produced In Compliance With The Fair Labor Standards Act, As Amended", 0.25, 0.5, 8, 0.25, size: 8, style: :bold)

    end

  end

end