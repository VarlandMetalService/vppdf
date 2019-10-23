# Class for printing bill of lading from System i.
class BillOfLading < VarlandPdf

  # Use letterhead.
  LETTERHEAD_FORMAT = :portrait

  # Allow read access to properties.
  attr_reader :shipper,
              :user,
              :ip
  
  # Constructor.
  def initialize(timestamp = nil, ip = nil)

    # Call parent constructor.
    super()

    # Load data.
    if timestamp.blank? || ip.blank?
      self.load_sample_data
    else
      @timestamp = timestamp
      @ip = ip
      self.load_data
    end
    @shipper = @data[:shipper]
    @user = @data[:user]
    @ip = @data[:ip]

    # Create extra pages for extra copies.
    (@data[:copies] - 1).times do |e| self.start_new_page end

    # Format pages.
    self.draw_format

    # Print data.
    self.draw_data

  end
  
  # Loads sample data.
  def load_sample_data
    @data = self.load_sample("bill_of_lading")
  end

  # Loads certification data.
  def load_data
    @data = self.load_json("http://as400railsapi.varland.com/v1/bill_of_lading?timestamp=#{@timestamp}&ip=#{@ip}")
  end

  # Prints data on bill.
  def draw_data

    # Set font.
    font = "SF Mono"
    color = '000000'
  
    # Format dates.
    ship_date = Time.iso8601(@data[:date]).strftime("%m/%d/%y")

    # Repeat format on all pages.
    self.repeat(:all) do

      # Carrier, shipper #s, and date.
      self.txtb(@data[:carrier], 1.171, 8.55 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      self.txtb(@data[:shipper], 6.75, 8.75 + 10.pt, 6.65, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      self.txtb(ship_date, 6.75, 8.55 + 10.pt, 6.65, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)

      # Ship to.
      if @data[:ship_to][:name].length == 2
        self.txtb(@data[:ship_to][:name][0], 1.006, 8.35 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
        self.txtb(@data[:ship_to][:name][1], 1.006, 8.175 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      else
        self.txtb(@data[:ship_to][:name][0], 1.006, 8.175 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      end
      self.txtb(@data[:ship_to][:address], 1.006, 8 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      self.txtb(@data[:ship_to][:city_state], 1.006, 7.825 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      self.txtb(@data[:ship_to][:zip].to_s.rjust(5, '0'), 3.65, 7.825 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)

      # Ship from.
      self.txtb(@data[:initials], 7.65, 7.825 + 10.pt, 4, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)

      # Table.
      y = 7.1 + 10.pt
      0.upto(8) do |i|
        self.txtb(@data[:units][i], 0.25, y, 1.25, 10.pt, size: 10, style: :bold, font: font, color: color) unless @data[:units][i] == 0
        self.txtb(@data[:hazardous][i], 1.5, y, 0.4, 10.pt, size: 10, style: :bold, font: font, color: color)
        self.txtb(@data[:descriptions][i], 1.95, y, 3.25, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
        self.txtb(@data[:weights][i], 5.25, y, 1.25, 10.pt, size: 10, style: :bold, font: font, color: color)
        self.txtb(@data[:rates][i], 6.5, y, 0.6, 10.pt, size: 10, style: :bold, font: font, color: color)
        y -= 0.193
      end

      # Draw special instructions.
      self.txtb(@data[:special_instructions][0], 0.35, 3.67 + 10.pt, 7.8, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      self.txtb(@data[:special_instructions][1], 0.35, 3.5325 + 10.pt, 7.8, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      self.txtb(@data[:special_instructions][2], 0.35, 3.395 + 10.pt, 7.8, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)

      # Check box for collect.
      self.txtb("XX", 7.377, 1.81 + 10.pt, 0.2, 0.2, size: 10, style: :bold, font: font, color: color) if @data[:collect]

      # Draw certification info.
      self.txtb(@data[:carrier], 4.95, 0.725 + 10.pt, 5, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)
      self.txtb(ship_date, 6.8, 0.575 + 10.pt, 5, 10.pt, size: 10, style: :bold, h_align: :left, font: font, color: color)

      # Draw signatures.
      if @data[:auto_sign]
        person = nil
        case @data[:user]
        when "TERRY"
          person = :terry_marshall
        when "ROB"
          person = :rob_caudill
        when "TIM"
          person = :tim_hudson
        when "MITCH"
          person = :mike_mitchell
        when "TONY"
          person = :tony_fuson
        when "CAP"
          person = :gerald_cappelletti
        when "ROBERT"
          person = :robert_beatty
        end
        unless person.blank?
          self.signature(person, 4.35, 2.425, 2.05, 0.5)
          self.signature(person, 0.95, 0.8, 2.05, 0.25, h_align: :left)
        end
      end

    end

  end

  # Prints standard graphics.
  def draw_format

    # Define line widths.
    thick_line = 0.012
    thin_line = 0.006

    # Number pages.
    self.font('Helvetica', style: :bold)
    string = "<page>"
    options = {:at => [0.in, 0.91.in],
               :width => 8.15.in,
               :align => :right,
               :size => 32,
               :start_count_at => 1}
    self.number_pages(string, options)

    # Print special content on only first page.
    self.repeat([1]) do
      self.txtb("ORIGINAL - NOT NEGOTIABLE", 0, 9 + 9.pt, 8.5, 9.pt, size: 9)
    end

    # Print special content on all pages except the first page.
    self.repeat(lambda {|pg| pg > 1}) do
      self.txtb("NOT NEGOTIABLE", 0, 9 + 9.pt, 8.5, 9.pt, size: 9)
    end

    # Repeat format on all pages.
    self.repeat(:all) do

      # Draw title.
      self.txtb("STRAIGHT BILL OF LADING - SHORT FORM", 0, 9.15 + 12.pt, 8.5, 12.pt, size: 12, style: :bold)

      # Labels for carrier, shipper, and date.
      self.txtb("Name of Carrier:", 0.25, 8.55 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("VMS Shipper #:", 0, 8.75 + 8.pt, 6.65, 8.pt, size: 8, h_align: :right)
      self.txtb("Date:", 0, 8.55 + 8.pt, 6.65, 8.pt, size: 8, h_align: :right)

      # Draw main rectangle.
      self.rect(0.25, 8.5, 8, 8, line_width: thick_line)

      # Ship to box.
      self.rect(0.25, 8.5, 4, 0.75, line_width: thick_line)
      self.txtb("TO:", 0.35, 8.35 + 8.pt, 4, 8.pt, size: 8, h_align: :left, style: :bold)
      self.txtb("Consignee", 0.35, 8.175 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("Street", 0.35, 8 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("Destination", 0.35, 7.825 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("Zip", 0, 7.825 + 8.pt, 3.55, 8.pt, size: 8, h_align: :right)

      # Ship from box.
      self.rect(4.25, 8.5, 4, 0.75, line_width: thick_line)
      self.txtb("FROM:", 4.35, 8.35 + 8.pt, 4, 8.pt, size: 8, h_align: :left, style: :bold)
      self.txtb("Shipper", 4.35, 8.175 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("Varland Metal Service, Inc.", 5.006, 8.175 + 8.pt, 4, 8.pt, size: 8, h_align: :left, style: :bold)
      self.txtb("Street", 4.35, 8 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("3231 Fredonia Avenue • (513) 861-0555", 5.006, 8 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("Origin", 4.35, 7.825 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("Initials", 0, 7.825 + 8.pt, 7.55, 8.pt, size: 8, h_align: :right)
      self.txtb("Cincinnati, OH 45229-3394", 5.006, 7.825 + 8.pt, 4, 8.pt, size: 8, h_align: :left)

      # Route & vehicle number boxes.
      self.txtb("Route", 0.25, 7.75, 6.25, 0.25, h_align: :left, h_pad: 0.1, size: 8, line_color: "000000", line_width: thick_line)
      self.txtb("Vehicle\nNumber", 6.5, 7.75, 1.75, 0.25, h_align: :left, h_pad: 0.1, v_pad: 0.025, size: 8, line_color: "000000", line_width: thick_line)

      # Draw table.
      table_options = {
        size: 8,
        v_pad: 0.025,
        line_color: "000000",
        line_width: thick_line
      }
      self.txtb("Number of\nShipping Units", 0.25, 7.5, 1.25, 0.25, table_options)
      self.txtb("HM*", 1.5, 7.5, 0.4, 0.25, table_options)
      self.txtb("Kind of Packaging, Description of Articles\nSpecial Marks and Exceptions", 1.9, 7.5, 3.35, 0.25, table_options)
      self.rect(5.25, 7.5, 1.25, 0.25, line_width: thick_line)
      self.txtb("§ Weight", 5.25, 7.5, 1.25, 0.135, size: 8, v_align: :bottom)
      self.txtb("(Subject to Correction)", 5.25, 7.365, 1.25, 0.115, size: 6, v_align: :top)
      self.txtb("Rate or\nClass", 6.5, 7.5, 0.6, 0.25, table_options)
      self.txtb("CHARGES", 7.1, 7.5, 1.15, 0.25, table_options)
      self.rect(0.25, 7.25, 8, 3.3, line_width: thick_line)
      [1.5, 1.9, 5.25, 6.5, 7.1].each do |x|
        self.vline(x, 7.25, 3.3)
      end

      # Special instructions box.
      self.rect(0.25, 3.95, 8, 0.6, line_width: thick_line)
      self.txtb('SPECIAL INSTRUCTIONS:', 0.35, 3.8075 + 8.pt, 4, 8.pt, size: 8, style: :bold, h_align: :left)

      # COD box.
      self.rect(0.25, 3.35, 4, 0.6, line_width: thick_line)
      self.rect(4.25, 3.35, 2.25, 0.6, line_width: thick_line)
      self.rect(6.5, 3.35, 1.75, 0.6, line_width: thick_line)
      self.txtb('REMIT C.O.D. TO:', 0.35, 3.2075 + 8.pt, 4, 8.pt, size: 8, style: :bold, h_align: :left)
      self.txtb('ADDRESS', 0.35, 3 + 8.pt, 4, 8.pt, size: 8, h_align: :left)
      self.txtb("ON COLLECT ON DELIVERY SHIPMENTS THE LETTERS \"COD\"\nMUST APPEAR BEFORE CONSIGNEE'S NAME - OR AS\nOTHERWISE PROVIDED IN ITEM 430, SEC. 1.", 4.3, 3.24 + 5.pt, 2.15, 0.6, size: 5, h_align: :left, v_align: :top)
      self.txtb('COD', 4.3, 2.8 + 12.pt, 2.15, 12.pt, size: 12, style: :bold, h_align: :left)
      self.txtb('Amt:', 5.05, 2.8 + 6.pt, 2.15, 6.pt, size: 6, h_align: :left)
      self.txtb('$', 5.245, 2.8 + 8.pt, 2.15, 8.pt, size: 8, h_align: :left)
      self.txtb('C.O.D. FEE', 6.6, 3.2075 + 8.pt, 1.75, 8.pt, size: 8, style: :bold, h_align: :left)
      self.rect(7.212, 2.95, 0.2, 0.2)
      self.rect(7.212, 3.15, 0.2, 0.2)
      self.txtb('PREPAID', 6.6, 3.15, 1.75, 0.2, size: 8, h_align: :left)
      self.txtb('COLLECT', 6.6, 2.95, 1.75, 0.2, size: 8, h_align: :left)
      self.txtb('$', 7.512, 2.95, 1.75, 0.2, size: 8, h_align: :left)

      # Miscellaneous box.
      self.rect(0.25, 2.75, 4, 1, line_width: thick_line)
      self.rect(4.25, 2.75, 2.25, 1, line_width: thick_line)
      self.rect(6.5, 2.75, 1.75, 1, line_width: thick_line)
      self.hline(0.25, 2.1, 4, line_width: thick_line)
      self.hline(4.35, 1.925, 2.05, line_width: thin_line)
      self.hline(6.5, 2.35, 1.75, line_width: thick_line)
      self.txtb("§ If the shipment moves between two ports by a carrier by water, the law requires that the bill of lading shall state whether it is\ncarrier's or shipper's weight.", 0.3, 2.65 + 5.pt, 3.9, 1, size: 5, h_align: :left, v_align: :top)
      self.txtb("† \"The fibre containers used for this shipment conform to the specifications set forth in the box maker's certificate thereon, and\nall other requirements of Rule 41 of the Uniform Freight Classification and Rule 5 of the National Motor Freight Classification.\"\n† \"Shipper's imprint in lieu of stamp; not a part of the bill of lading approved by the Interstate Commerce Commission.\"", 0.3, 2.35 + 5.pt, 3.9, 1, size: 5, h_align: :left, v_align: :top)
      self.txtb("NOTE: Where the rate is dependent on value, shippers are required to state specifically in writing the agreed or declared value\nof the property. <strong>Shipper hereby specifically states agreed or declared value of this property to be not exceeding</strong>", 0.3, 2.015 + 5.pt, 3.9, 1, size: 5, h_align: :left, v_align: :top)
      self.txtb('$', 0.3, 1.79 + 9.pt, 1.75, 9.pt, size: 9, h_align: :left, v_align: :center)
      self.txtb('PER', 2.3, 1.79 + 9.pt, 1.75, 9.pt, size: 9, h_align: :left, v_align: :center)
      self.txtb("  Subject to Section 7 of the conditions, if this shipment is to be\ndelivered to the consignee without recourse on the consignor, the\nconsignor shall sign the following statement:\n  The carrier shall not make delivery of this shipment without payment\nof freight and all other lawful charges.", 4.3, 2.65 + 5.pt, 2.15, 1, size: 5, h_align: :left, v_align: :top)
      self.txtb("Signature of Consignor", 4.25, 1.83 + 7.pt, 2.25, 7.pt, size: 7, h_align: :center)
      self.txtb("TOTAL\nCHARGES", 6.6, 2.75, 1.55, 0.4, size: 7, h_align: :left)
      self.txtb("FREIGHT CHARGES", 6.5, 2.24 + 6.pt, 1.75, 6.pt, size: 6, h_align: :center)
      self.txtb("FREIGHT PREPAID\nexcept when box\nat right is checked", 6.55, 1.95 + 6.pt, 1.65, 3 * 6.pt, size: 6, h_align: :left, v_align: :bottom)
      self.txtb("Check box if\ncharges are to\nbe collect", 7.667, 1.95 + 6.pt, 1.65, 3 * 6.pt, size: 6, h_align: :left, v_align: :bottom)
      self.rect(7.377, 1.95, 0.2, 0.2, line_width: thick_line)

      # Legal box.
      self.rect(0.25, 1.75, 8, 0.75, line_width: thick_line)
      left = "  RECEIVED, subject to the classifications and lawfully filed tariffs in effect on the date of the issue of this Bill of Lading, the\nproperty described above in apparent good order, except as noted (contents and condition of contents of packages unknown),\nmarked, cosigned and destined as indicated above which said carrier (the word carrier being understood throughout this\ncontract as meaning any person or corporation in possession of the property under the contract) agrees to carry to its usual\nplace of delivery at said destination if on its route, otherwise to deliver to another carrier on the route to said destination. It is\nmutually agreed as to each carrier of all or any of said property over all or any portion of said route to destination and as to\neach party at any time interested in all or any said property, that every service to be performed hereunder shall be subject to all"
      right = "the Bill of Lading terms and conditions in the governing classification on the date of shipment. Shipper hereby certifies that he\nis familiar with all the Bill of Lading terms and conditions in the governing classification and the said terms and conditions are\nhereby agreed to by the shipper and accepted for himself and his assigns. NOTICE: Freight moving under this Bill of Lading is\nsubject to the classifications and lawfully filed tariffs in effect on the date of this Bill of Lading. This notice supersedes and\nnegates any claimed, alleged or asserted oral or written contract, promise, representation or understanding between the\nparties with respect to this freight, except to the extent of any written contract which established lawful contract carriage and is\nsigned by authorized representatives of both parties to the contract."
      self.txtb(left, 0.3, 1.80 + 5.pt, 3.9, 0.75, size: 5, h_align: :left, v_align: :bottom)
      self.txtb(right, 4.3, 1.80 + 5.pt, 3.9, 0.75, size: 5, h_align: :left, v_align: :bottom)

      # Certification box.
      self.rect(0.25, 1, 8, 0.5)
      self.txtb("This is to certify that the above named materials are properly classified, packaged, marked, and labeled, and are in proper condition for transportation according to the applicable regulations of the Department of Transportation.", 0.35, 0.875 + 5.pt, 7.9, 5.pt, size: 5, h_align: :left)
      self.txtb("SHIPPER", 0.35, 0.725 + 8.pt, 7.9, 8.pt, size: 8, h_align: :left)
      self.txtb("Varland Metal Service, Inc. • Cincinnati OH 45229-3394", 0.95, 0.725 + 8.pt, 7.9, 8.pt, size: 8, style: :bold, h_align: :left)
      self.txtb("PER", 0.35, 0.575 + 8.pt, 7.9, 8.pt, size: 8, h_align: :left)
      self.txtb("CARRIER", 4.35, 0.725 + 8.pt, 7.9, 8.pt, size: 8, h_align: :left)
      self.txtb("PER", 4.35, 0.575 + 8.pt, 7.9, 8.pt, size: 8, h_align: :left)
      self.txtb("DATE", 0, 0.575 + 8.pt, 6.7, 8.pt, size: 8, h_align: :right)

      # Footer text.
      self.txtb('* MARK WITH "X" TO DESIGNATE HAZARDOUS MATERIAL AS DEFINED IN TITLE 49 OF FEDERAL REGULATIONS', 0.25, 0.4 + 6.pt, 8, 6.pt, size: 6, style: :bold, h_align: :left)
      self.txtb('Permanent post-office address of shipper.', 0.25, 0.3 + 5.pt, 8, 5.pt, size: 5, style: :bold, h_align: :left)

    end

  end

end