# Class for printing quote from System i.
class Quote < VarlandPdf

  # Use letterhead.
  LETTERHEAD_FORMAT = :portrait
  
  # Constructor.
  def initialize(quote_number = nil)

    # Call parent constructor.
    super()

    # Store quote properties.
    @widths = [0.5, 1.75, 3.25, 1.25, 1.25]
    @table_height = 5.75
    @line_height = 0.14375

    # Load data.
    if quote_number.blank?
      self.load_sample_data
    else
      @quote_number = quote_number
      self.load_data
    end

    # Initialize page numbers.
    @first_page_number = 1
    @current_page_number = 1

    # Reference first quote.
    @first_quote = @data[:quotes][0]
    @current_customer = @first_quote[:customer][:code]
    @current_number = @first_quote[:quote]
    @printed_header = false

    # Draw format.
    self.draw_format

    # Draw data.
    self.draw_data

  end
  
  # Loads sample data.
  def load_sample_data
    @data = self.load_sample("quote")
  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://as400railsapi.varland.com/v1/quote?quote=#{@quote_number}")
  end

  # Calculates lines required for part.
  def calc_part_lines(part)

    # Initialize to number of lines of part name, description, and process specification.
    blocks = 0
    lines = 0
    [:part_name, :part_description, :process_specification].each do |property|
      blocks += 1 unless part[property].length == 0
      lines += part[property].length
    end
    lines += (blocks - 1)

    # If price column requires more lines, store.
    price_lines = 1
    price_lines += 2 if part[:total_minimum] != 0
    price_lines += 2 if part[:total_setup] != 0

    # Store higher count.
    max = [lines, price_lines].max

    # Add lines for remarks if necessary.
    unless part[:remarks].length == 0
      max += part[:remarks].length
    end

    # Return lines.
    return max

  end

  # Calculates vertical space required for part.
  def calc_part_height(part, has_effective_date, has_confirmation_message, text_remarks_length)
    return 1.45 + (has_confirmation_message ? 0.25 : 0) + (has_effective_date ? 0.375 : 0) + self.calc_part_lines(part) * @line_height + (part[:remarks].length == 0 ? 0 : 0.25) + text_remarks_length * @line_height + (text_remarks_length == 0 ? 0 : 0.25)
  end

  # Formats unit price.
  def format_unit_price(part)

    # Round unit price to 2..5 decimals.
    price = self.format_number(part[:total_price],
                               decimals: 5,
                               delimiter: nil,
                               strip_insignificant_zeros: true)
    count_decimals = (price.include?('.') ? price.split('.').last.size : 0)
    if count_decimals < 2
      price = self.format_number(price.to_f, decimals: 2, delimiter: nil)
    end

    # Define labels for price per codes.
    labels = {
      "#": "/LB",
      C: "/CWT",
      E: "/EACH",
      M: "/M PCS"
    }

    # Return unit price.
    return "$#{price}#{labels[part[:price_per].to_sym]}"

  end

  # Draws header.
  def draw_header

    # Stop if already drew header.
    return if @printed_header

    # Set printed header flag.
    @printed_header = true

    # Format dates.
    quote_date = Time.iso8601(@first_quote[:quote_date]).strftime("%m/%d/%y")

    # Print header information on each page.
    self.repeat(@first_page_number..@current_page_number) do

      # Draw address.
      y = 9
      text = @first_quote[:requested_by].blank? ? "<b>" : "Attn: <b>#{@first_quote[:requested_by]}\n"
      text << "#{@first_quote[:customer][:name].join("\n")}\n#{@first_quote[:customer][:address]}\n#{@first_quote[:customer][:city]}, #{@first_quote[:customer][:state]} #{@first_quote[:customer][:zip].to_s.rjust(5, '0')}</b>"
      self.txtb(text,
                0.25,
                y,
                4,
                0.75,
                size: 9,
                h_align: :left,
                v_align: :top,
                v_pad: 0.05)
      text = "<b>#{@first_quote[:customer][:code]}</b>"
      unless @first_quote[:phone] == 0 && @first_quote[:fax] == 0
        text << "\n\n"
        text << "Phone: <b>#{self.helpers.number_to_phone(@first_quote[:phone], area_code: true)}</b>\n" unless @first_quote[:phone] == 0
        text << "Fax: <b>#{self.helpers.number_to_phone(@first_quote[:fax], area_code: true)}</b>" unless @first_quote[:fax] == 0
      end
      self.txtb(text,
                4,
                y,
                3.25,
                0.75,
                size: 9,
                h_align: :left,
                v_align: :top,
                v_pad: 0.05)

      # Draw date.
      self.txtb("Date: <b>#{quote_date}</b>",
                6,
                y,
                2.25,
                0.75,
                size: 9,
                h_align: :right,
                v_align: :top,
                v_pad: 0.05)

    end

  end

  # Draws data.
  def draw_data

    # Initialize printing.
    y = 8
    footer_height = 1.75
    height_remaining = y - footer_height

    # Print each quote.
    @data[:quotes].each_with_index do |quote, quote_index|

      # If quote is for a new customer, move to new page and print headers in previous section.
      if quote[:customer][:code] != @current_customer || (quote[:quote] != @current_number && quote[:page_control] == 'Y')
        self.draw_header
        self.start_new_page
        @current_page_number += 1
        self.draw_format
        y = 8
        height_remaining = y - footer_height
        @first_page_number = @current_page_number
        @first_quote = quote
        @printed_header = false
        @current_customer = quote[:customer][:code]
        @current_number = quote[:quote]
      end

      # Format dates.
      effective_date = quote[:effective_date].nil? ? nil : Time.iso8601(quote[:effective_date]).strftime("%m/%d/%y")

      # Print parts.
      quote[:parts].each_with_index do |part, part_index|

        # Move to next page if necessary.
        height_required = self.calc_part_height(part, !effective_date.nil?, quote[:confirming], quote[:text_remarks].length).round(5)
        lines_required = self.calc_part_lines(part)
        if height_required > height_remaining
          self.start_new_page
          @current_page_number += 1
          self.draw_format
          y = 8
          height_remaining = y - footer_height
        end

        # Draw quote number box.
        self.txtb("Quotation ##{quote[:quote]}", 0.25, y, 8, 0.35, fill_color: "e3e3e3", line_color: "000000", h_align: :left, h_pad: 0.1, style: :bold)
        self.txtb("Your Request #: <b>#{quote[:request_number]}</b>", 1.75, y, 6.75, 0.35, h_align: :left) unless quote[:request_number].blank?
        self.txtb("Please refer to this number on all correspondence and orders", 0.25, y, 8, 0.35, size: 8, style: :italic, h_align: :right, h_pad: 0.1)

        # Draw table headers.
        header_options = {fill_color: 'e3e3e3', line_color: '000000', size: 8, style: :bold}
        self.txtb("Code", 0.25, y - 0.35, @widths[0], 0.25, header_options)
        self.txtb("Part Number", 0.25 + @widths[0], y - 0.35, @widths[1], 0.25, header_options)
        self.txtb("Part Description/Process Specification", 0.25 + @widths[0..1].sum, y - 0.35, @widths[2], 0.25, header_options)
        self.txtb("Quantity", 0.25 + @widths[0..2].sum, y - 0.35, @widths[3], 0.25, header_options)
        self.txtb("Price", 0.25 + @widths[0..3].sum, y - 0.35, @widths[4], 0.25, header_options)

        # Draw vertical lines.
        self.vline(0.25, y - 0.6, @line_height * lines_required + 0.1)
        @widths.each_index do |i|
          self.vline(0.25 + @widths[0..i].sum, y - 0.6, @line_height * lines_required + 0.1)
        end

        # Print part.
        self.txtb(part[:process_code], 0.25, y - 0.65, @widths[0], @line_height, size: 9)
        self.txtb(part[:part_id], 0.25 + @widths[0..0].sum, y - 0.65, @widths[1], @line_height, h_align: :left, h_pad: 0.1, size: 9)
        self.txtb(part[:sub_id], 0.25 + @widths[0..0].sum, y - 0.65, @widths[1], @line_height, h_align: :right, h_pad: 0.1, size: 9)
        lines = 0
        part[:part_name].each do |line|
          self.txtb(line, 0.25 + @widths[0..1].sum, y - 0.65 - lines * @line_height, @widths[2], @line_height, h_align: :left, h_pad: 0.1, size: 9)
          lines += 1
        end
        lines += 1 unless part[:part_name].length == 0
        part[:part_description].each do |line|
          self.txtb(line, 0.25 + @widths[0..1].sum, y - 0.65 - lines * @line_height, @widths[2], @line_height, h_align: :left, h_pad: 0.1, size: 9)
          lines += 1
        end
        lines += 1 unless part[:part_description].length == 0
        part[:process_specification].each do |line|
          self.txtb(line, 0.25 + @widths[0..1].sum, y - 0.65 - lines * @line_height, @widths[2], @line_height, h_align: :left, h_pad: 0.1, size: 9)
          lines += 1
        end
        lines = 2
        self.txtb("#{part[:quantity]} #{part[:quantity_unit]}", 0.25 + @widths[0..2].sum, y - 0.65, @widths[3], @line_height, size: 9)
        self.txtb(self.format_unit_price(part), 0.25 + @widths[0..3].sum, y - 0.65, @widths[4], @line_height, size: 9)
        unless part[:total_setup] == 0
          self.txtb("SETUP / LOT", 0.25 + @widths[0..2].sum, y - 0.65 - lines * @line_height, @widths[3], @line_height, size: 9)
          self.txtb("$#{self.format_number(part[:total_setup], decimals: 2)}", 0.25 + @widths[0..3].sum, y - 0.65 - lines * @line_height, @widths[4], @line_height, size: 9)
          lines += 2
        end
        unless part[:total_minimum] == 0
          self.txtb("MINIMUM", 0.25 + @widths[0..2].sum, y - 0.65 - lines * @line_height, @widths[3], @line_height, size: 9)
          self.txtb("$#{self.format_number(part[:total_minimum], decimals: 2)}", 0.25 + @widths[0..3].sum, y - 0.65 - lines * @line_height, @widths[4], @line_height, size: 9)
        end

        # Print remarks.
        remarks_y = 0
        unless (part[:remarks].length == 0)
          remarks_y = y - (@line_height * (lines_required - part[:remarks].length))
          self.txtb("Remarks:", 0.25, remarks_y - 0.7, 8, 0.25 + part[:remarks].length * @line_height, fill_color: "ffffff", line_color: "000000", h_align: :left, v_align: :top, h_pad: 0.05, v_pad: 0.05, size: 8, style: :italic)
          part[:remarks].each_with_index do |line, index|
            self.txtb(line,
                      0.25,
                      remarks_y - 0.9 - index * @line_height,
                      8,
                      @line_height,
                      size: 9,
                      h_align: :left,
                      h_pad: 0.1)
          end
        end

        # Print text remarks if necessary.
        unless (quote[:text_remarks].length == 0)
          remarks_y = remarks_y - (0.25 + part[:remarks].length * @line_height)
          text = part[:remarks].length == 0 ? "Remarks:" : "Additional Remarks:"
          self.txtb(text, 0.25, remarks_y - 0.7, 8, 0.25 + quote[:text_remarks].length * @line_height, fill_color: "ffffff", line_color: "000000", h_align: :left, v_align: :top, h_pad: 0.05, v_pad: 0.05, size: 8, style: :italic)
          quote[:text_remarks].each_with_index do |line, index|
            self.txtb(line,
                      0.25,
                      remarks_y - 0.9 - index * @line_height,
                      8,
                      @line_height,
                      size: 9,
                      h_align: :left,
                      h_pad: 0.1)
          end
        end

        # Set offset for confirmation message if necessary.
        confirmation_offset = quote[:confirming] ? 0.25 : 0

        # Draw effective date.
        unless effective_date.nil?
          self.txtb("Effective Date:", 0.25, y - height_required + 1.125 + confirmation_offset, 4, 0.375, line_color: '000000', size: 8, style: :italic, h_align: :left, v_align: :top, h_pad: 0.05, v_pad: 0.05)
          self.txtb("REVISED PRICING EFFECTIVE #{effective_date}", 0.25, y - height_required + 1 + confirmation_offset, 4, 0.25, h_align: :left, h_pad: 0.1, size: 9, style: :bold)
        end

        # Draw terms, FOB, and request number.
        self.txtb("Terms:", 0.25, y - height_required + 0.75 + confirmation_offset, 4, 0.375, line_color: '000000', size: 8, style: :italic, h_align: :left, v_align: :top, h_pad: 0.05, v_pad: 0.05)
        self.txtb("FOB:", 0.25, y - height_required + 0.375 + confirmation_offset, 4, 0.375, line_color: '000000', size: 8, style: :italic, h_align: :left, v_align: :top, h_pad: 0.05, v_pad: 0.05)
        self.txtb(quote[:quote_terms].gsub(/\ATERMS:\s+/, ''), 0.25, y - height_required + 0.625 + confirmation_offset, 4, 0.25, h_align: :left, h_pad: 0.1, size: 9, style: :bold)
        self.txtb(quote[:quote_fob], 0.25, y - height_required + 0.25 + confirmation_offset, 4, 0.25, h_align: :left, h_pad: 0.1, size: 9, style: :bold)

        # Draw quoted by name and signature.
        offset = 0.75 + (effective_date.nil? ? 0 : 0.375)
        self.txtb("Quoted By:",
                  4.25,
                  y - height_required + offset + confirmation_offset,
                  4,
                  offset,
                  line_color: '000000',
                  size: 8,
                  style: :italic,
                  h_align: :left,
                  v_align: :top,
                  h_pad: 0.05,
                  v_pad: 0.05)
        self.hline(4.35, y - height_required + 0.25 + confirmation_offset, 3.8, line_width: 0.001)
        sig_y = y - height_required + offset + confirmation_offset
        sig_height = offset - 0.25
        if sig_height > 0.5
          sig_y -= (sig_height - 0.5)
          sig_height = 0.5
        end
        self.signature(quote[:quoted_by].gsub(/\s/, '_').downcase.to_sym, 4.35, sig_y, 3.8, sig_height, h_align: :left)
        self.txtb(quote[:quoted_by].namecase, 4.35, y - height_required + 0.25 + confirmation_offset, 3.8, 0.25, v_align: :top, v_pad: 0.05, h_align: :left, size: 9, style: :bold)

        # Draw confirming box if necessary.
        self.txtb("***** CONFIRMING *****", 0.25, y - height_required + 0.25, 8, 0.25, size: 9, style: :bold, line_color: "000000", fill_color: "e3e3e3", transform: :double_space_between) if quote[:confirming]

        # Move down page and decrease space remaining.
        y -= (height_required + 0.25)
        height_remaining -= (height_required + 0.25)

      end

    end

    # Draw header.
    self.draw_header

  end

  # Draws standard format.
  def draw_format

    # Draw quote number.
    self.txtb("QUOTATION ##{@first_quote[:quote]}",
              0.25,
              9.4,
              8,
              0.25,
              size: 24,
              style: :bold)

    # Draw quote features.
    self.txtb("All quotations from Varland Plating include plating certifications, PPAP documentation, and annual\nsalt spray validation when applicable. Our typical lead time is 5 business days in-house.",
              0.25,
              1.5,
              8,
              0.5,
              size: 10,
              style: :bold,
              line_color: "000000",
              fill_color: "e3e3e3")
    
    # Draw graphic.
    self.standard_graphic('iso', 0.25, 0.75, 0.89, 0.5, h_align: :left)
    self.standard_graphic('itar', 1.39, 0.75, 1.57, 0.5, h_align: :left)

    # Draw compliance policy.
    self.txtb("<b>CORPORATE COMPLIANCE POLICY</b>\nVarland Plating Company certifies that its pollution abatement system is operated in compliance\nwith U.S. EPA, state, and local regulations applicable to waste water discharge and sludge disposal.",
              3.21,
              0.75,
              5.04,
              0.5,
              size: 8)

  end

end