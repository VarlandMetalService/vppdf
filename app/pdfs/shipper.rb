# Class for printing shipper from System i.
class Shipper < VarlandPdf

    # Landscape orientation and special letterhead format for shippers.
    PAGE_ORIENTATION = :landscape
    # LETTERHEAD_FORMAT = :packing_list

    # Constructor.
    def initialize(shipper = nil)

      # Call parent constructor.
      super()

      # Load data.
      if shipper.blank?
        self.load_sample_data
      else
        @shipper = shipper
        self.load_data
      end

      # If missing any thickness data for cert, print.
      result = self.validate_thickness
      return unless result

      # Calculate pages needed.
      pages = self.calc_shipper_pages

      # Setup pages for each format.
      page_count = 1
      @vms_pages = [1]
      (2..pages).each do |i|
        self.start_new_page
        @vms_pages << i
        page_count += 1
      end
      @packing_list_pages = []
      (1..pages).each do |i|
        self.start_new_page
        @packing_list_pages << page_count + i
      end

      # Format packing list pages.
      self.draw_shipper_format

      # Print packing list data.
      self.draw_shipper_data

      # Write pages for certifications when necessary.
      @data[:orders].each_with_index do |order, index|
        @order = order
        @certification = @order[:certification]
        next if @certification[:code].blank?
        self.start_new_page(layout: :portrait)
        self.draw_certification_format
        self.draw_certification_data
      end

    end

    # Validates thickness information for certifications.
    def validate_thickness

      # Check requirements for each order.
      missing_thickness = []
      @data[:orders].each do |order|
        next if order[:certification][:thickness_format].blank?
        if order[:certification][:thickness_format] == "I" || order[:certification][:thickness_format] == "M"
          missing_thickness << order[:shop_order] unless order[:thickness_data][:found]
        end
      end

      # If found missing info, print error message on page.
      if missing_thickness.size > 0
        self.txtb("Missing thickness data for certification for orders: #{missing_thickness.join(", ")}", 0.25, 6, 10.5, 3.5, style: :bold, size: 30, color: "ff0000", transform: :uppercase)
      end

      # Return failure.
      return missing_thickness.size == 0

    end

    # Calculates number of pages for shipper.
    def calc_shipper_pages

      # Define height of table and line height.
      table_height = 4.5
      line_height = 0.15

      # Calculate lines per page.
      lines_per_page = (table_height / line_height).to_i

      # Initialize page count and lines remaining.
      pages = 1
      lines_remaining = lines_per_page

      # Check each order, adding pages when necessary.
      @data[:orders].each do |order|
        lines_needed = self.calc_order_lines(order)
        if lines_needed > lines_remaining
          pages += 1
          lines_remaining = lines_per_page
        end
        lines_remaining -= lines_needed + 2
      end

      # Return number of pages.
      return pages

    end

    # Calculates number of lines required for order.
    def calc_order_lines(order)

      # Initialize 1 + number of lines in part name.
      lines = 1 + order[:part_name].length

      # If number of lines of purchase order > lines, store.
      lines = order[:purchase_orders].length if order[:purchase_orders].length > lines

      # If number of lines of process specification > lines, store.
      lines = order[:process_specification].length if order[:process_specification].length > lines

      # If order has remarks, add lines.
      unless order[:remarks].length == 0
        lines += order[:remarks].length + 1
      end

      # Return number of lines.
      return lines

    end

    # Loads sample data.
    def load_sample_data
      @data = self.load_sample("shipper")
    end

    # Loads certification data.
    def load_data
      @data = self.load_json("http://as400railsapi.varland.com/v1/shipper?shipper=#{@shipper}")
    end

    # Draws data on shipper.
    def draw_shipper_data

      # Print page numbers.
      @vms_pages.each_with_index do |number, index|
        self.repeat([number, @packing_list_pages[index]]) do
          self.txtb("PAGE #{index + 1} OF #{@vms_pages.length}", 9.75, 6.1, 1, 0.25, style: :bold, size: 9)
        end
      end

      # Print header information on each page.
      self.repeat(@vms_pages + @packing_list_pages) do

        # Format dates.
        ship_date = Time.iso8601(@data[:orders][0][:ship_date]).strftime("%m/%d/%y")

        # Print sold to and ship to.
        self.txtb("#{@data[:customer][:name].join("\n")}\n#{@data[:customer][:address]}\n#{@data[:customer][:city]}, #{@data[:customer][:state]} #{@data[:customer][:zip].to_s.rjust(5, '0')}", 0.5, 6.75, 3, 1, v_align: :top, h_align: :left, style: :bold)
        self.txtb("#{@data[:ship_to][:name].join("\n")}\n#{@data[:ship_to][:address]}\n#{@data[:ship_to][:city]}, #{@data[:ship_to][:state]} #{@data[:ship_to][:zip].to_s.rjust(5, '0')}", 5.75, 6.75, 3, 1, v_align: :top, h_align: :left, style: :bold)

        # Print shipper number.
        self.txtb(@data[:shipper], 9.75, 6.5, 1, 0.25, style: :bold, size: 16)

        # Print customer code.
        self.txtb(@data[:customer][:code], 9.75, 6.25, 1, 0.25, style: :bold, size: 9)

        # Print certification date, ship via, and vendor code.
        self.txtb("SHIP DATE: <b>#{ship_date}</b>", 0.25, 5.77, 5.25, 0.25, v_align: :bottom, h_align: :left, size: 9)
        self.txtb("SHIP VIA: <b>#{@data[:how_shipped][:description]}</b>", 5.5, 5.77, 3, 0.25, v_align: :bottom, h_align: :left, size: 9)
        unless @data[:customer][:vendor_id].blank?
          self.txtb("VENDOR: <b>#{@data[:customer][:vendor_id]}</b>", 9.75, 5.77, 1, 0.25, v_align: :bottom, h_align: :right, size: 9)
        end

      end

      # Print data.
      page_index = 0
      table_height = 4.5
      line_height = 0.15
      lines_per_page = (table_height / line_height).to_i
      lines_remaining = lines_per_page
      y = 5.23
      @data[:orders].each do |order|

        # Calculate lines needed. Move to next page if necessary.
        lines_needed = self.calc_order_lines(order)
        if lines_needed > lines_remaining
          page_index += 1
          lines_remaining = lines_per_page
          y = 5.23
        end

        # Format dates.
        so_date = Time.iso8601(order[:shop_order_date]).strftime("%m/%d/%y")
        entry_date = Time.iso8601(order[:date_entered]).strftime("%m/%d/%y")

        # Print order details.
        self.repeat([@vms_pages[page_index], @packing_list_pages[page_index]]) do
          self.txtb(order[:shop_order], 0.25, y, 0.6, line_height, size: 9, style: :bold)
          self.txtb(entry_date.blank? ? so_date : entry_date, 0.85, y, 0.75, line_height, size: 9, style: :bold)
          self.txtb(self.format_number(order[:pounds], decimals: 2), 1.6, y, 0.75, line_height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
          self.txtb(self.format_number(order[:pieces]), 2.35, y, 0.75, line_height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
          self.txtb("#{self.format_number(order[:containers])} #{order[:container_type]}", 3.1, y, 1, line_height, size: 9, style: :bold)
          self.txtb(order[:purchase_orders].join("\n"), 4.1, y, 1.4, line_height * order[:purchase_orders].length, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
          self.txtb("#{order[:part_id]}\n#{order[:part_name].join("\n")}", 5.5, y, 1.85, line_height * (order[:part_name].length + 1), size: 9, style: :bold, h_align: :left, h_pad: 0.05)
          self.txtb(order[:sub_id], 5.5, y, 1.85, line_height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
          self.txtb(order[:process_specification].join("\n"), 7.35, y, 2.6, line_height * order[:process_specification].length, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
          self.txtb(order[:is_complete] ? "COMPLETE" : "PARTIAL", 9.95, y, 0.8, line_height, size: 9, style: :bold)
          unless (order[:remarks].length == 0)
            remarks_y = y - (line_height * (lines_needed - order[:remarks].length))
            label_width = self.calc_width("REMARKS: ", style: :normal, size: 8)
            self.rect(0.3, remarks_y + 0.05, 10.4, 0.1 + (line_height * order[:remarks].length), fill_color: "e3e3e3")
            self.txtb("REMARKS:", 0.35, remarks_y, label_width, line_height)
            self.txtb(order[:remarks].join("\n"), 0.35 + label_width, remarks_y, 9, line_height * order[:remarks].length, size: 10, style: :bold, h_align: :left)
          end
          y -= line_height * (lines_needed + 2)
        end

        # Decrease lines remaining.
        lines_remaining -= (lines_needed + 2)

      end

    end

    # Draws data on certification.
    def draw_certification_data

      # Format dates.
      ship_date = Time.iso8601(@order[:ship_date]).strftime("%m/%d/%y")
      so_date = @order[:shop_order_date].blank? ? nil : Time.iso8601(@order[:shop_order_date]).strftime("%m/%d/%y")
      entry_date = @order[:date_entered].blank? ? nil : Time.iso8601(@order[:date_entered]).strftime("%m/%d/%y")

      # Determine if thickness included.
      includes_thickness = !(@certification[:thickness_format] == "N" || @certification[:thickness_format].blank?)
      has_alloy = !@order[:thickness_data][:mean_alloy].blank?

      # Print certification date.
      self.txtb("CERTIFICATION DATE: <b>#{ship_date}</b>", 0.25, 8.875, 8, 0.2, size: 12)

      # Print order information.
      order_info_height = 0.75
      if @order[:purchase_orders].length > 3
        order_info_height = 1.25
      end
      data_options = {line_color: "000000", fill_color: 'ffffff', size: 9, style: :bold}
      self.txtb("#{@data[:customer][:name].join("\n")}\n#{@data[:customer][:address]}\n#{@data[:customer][:city]}, #{@data[:customer][:state]} #{@data[:customer][:zip].to_s.rjust(5, '0')}", 0.25, 8.175, 2.5, order_info_height, v_align: :top, h_align: :left, style: :bold, line_color: "000000", h_pad: 0.05, v_pad: 0.05)
      self.txtb("<b>#{@order[:shop_order]}</b>\n<font size=\"8\">#{entry_date.blank? ? so_date : entry_date}</font>", 2.75, 8.175, 0.75, order_info_height, v_align: :top, h_align: :center, line_color: "000000", h_pad: 0.05, v_pad: 0.05)
      self.txtb(@order[:purchase_orders].join("\n"), 3.5, 8.175, 1.5, order_info_height, v_align: :top, h_align: :left, line_color: "000000", h_pad: 0.05, v_pad: 0.05, style: :bold)
      self.txtb("#{@order[:part_id]}\n#{@order[:part_name].join("\n")}", 5, 8.175, 1.85, order_info_height, v_align: :top, h_align: :left, line_color: "000000", h_pad: 0.05, v_pad: 0.05, style: :bold)
      self.txtb(@order[:sub_id], 5, 8.175, 1.85, order_info_height, v_align: :top, h_align: :right, line_color: "000000", h_pad: 0.05, v_pad: 0.05, style: :bold)
      self.txtb("<font size=\"8\">Pounds:</font> <b>#{self.format_number(@order[:pounds], decimals: 2, strip_insignificant_zeros: true)}</b>\n<font size=\"8\">Pieces:</font> <b>#{self.format_number(@order[:pieces])}</b>\n\n<b>#{self.format_number(@order[:containers])} #{@order[:container_type]}</b>", 6.85, 8.175, 1.4, order_info_height, v_align: :top, h_align: :left, line_color: "000000", h_pad: 0.05, v_pad: 0.05)

      # Draw boxes for process specification and thickness table.
      process_x = 0.25 #4.375
      process_y = 7.925 - order_info_height
      thickness_x = 4.375 #0.25
      thickness_y = 7.925 - order_info_height
      process_width = 3.875
      thickness_width = process_width
      check_number_width = 1
      thickness_value_width = 1.4375
      header_options = { line_color: '000000', fill_color: 'e3e3e3', size: 8 }
      small_header_options = { line_color: '000000', fill_color: 'e3e3e3', size: 7 }
      if includes_thickness
        self.txtb("PLATING THICKNESS DATA", thickness_x, thickness_y, 3.875, 0.25, header_options)
        thickness_y -= 0.25
        self.txtb("CHECK #", thickness_x, thickness_y, 1, 0.25, small_header_options)
        if has_alloy
          self.txtb("THICKNESS", thickness_x + check_number_width, thickness_y, thickness_value_width, 0.25, small_header_options)
          self.txtb("ALLOY %", thickness_x + check_number_width + thickness_value_width, thickness_y, thickness_value_width, 0.25, small_header_options)
        else
          thickness_value_width *= 2
          self.txtb("THICKNESS", thickness_x + check_number_width, thickness_y, thickness_value_width, 0.25, small_header_options)
        end
        thickness_y -= 0.25
        self.txtb("PROCESS SPECIFICATION", process_x, process_y, process_width, 0.25, header_options)
        process_y -= 0.25
      else
        # process_x = 2.3125
        self.txtb("PROCESS SPECIFICATION", process_x, process_y, process_width, 0.25, header_options)
        process_y -= 0.25
      end

      # return

      # # Print sold to and ship to.
      # self.txtb("#{@data[:customer][:name].join("\n")}\n#{@data[:customer][:address]}\n#{@data[:customer][:city]}, #{@data[:customer][:state]} #{@data[:customer][:zip].to_s.rjust(5, '0')}", 0.5, 6.75, 3, 1, v_align: :top, h_align: :left, style: :bold)
      # self.txtb("#{@data[:ship_to][:name].join("\n")}\n#{@data[:ship_to][:address]}\n#{@data[:ship_to][:city]}, #{@data[:ship_to][:state]} #{@data[:ship_to][:zip].to_s.rjust(5, '0')}", 5.75, 6.75, 3, 1, v_align: :top, h_align: :left, style: :bold)

      # # Print shipper number.
      # self.txtb(@data[:shipper], 9.75, 6.5, 1, 0.25, style: :bold, size: 16)

      # # Print customer code.
      # self.txtb(@data[:customer][:code], 9.75, 6.25, 1, 0.25, style: :bold, size: 9)

      # # Print certification date, ship via, and vendor code.
      # ship_via = @data[:how_shipped][:code] == "F" ? @data[:orders][0][:shipping_remark] : @data[:how_shipped][:description]
      # self.txtb("CERTIFICATION DATE: <b>#{ship_date}</b>", 0.25, 5.77, 5.25, 0.25, v_align: :bottom, h_align: :left, size: 9)
      # self.txtb("SHIP VIA: <b>#{ship_via}</b>", 5.5, 5.77, 3, 0.25, v_align: :bottom, h_align: :left, size: 9)
      # unless @data[:customer][:vendor_id].blank?
      #   self.txtb("VENDOR: <b>#{@data[:customer][:vendor_id]}</b>", 9.75, 5.77, 1, 0.25, v_align: :bottom, h_align: :right, size: 9)
      # end

      # # Print data.
      # y = 4.73
      # height = 0.14
      # self.txtb(@order[:shop_order], 0.25, y, 0.6, height, size: 9, style: :bold)
      # self.txtb(entry_date.blank? ? so_date : entry_date, 0.85, y, 0.75, height, size: 9, style: :bold)
      # self.txtb(self.format_number(@order[:pounds], decimals: 2), 1.6, y, 0.75, height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
      # self.txtb(self.format_number(@order[:pieces]), 2.35, y, 0.75, height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
      # self.txtb("#{self.format_number(@order[:containers])} #{@order[:container_type]}", 3.1, y, 1, height, size: 9, style: :bold)
      # self.txtb(@order[:purchase_orders].join("\n"), 4.1, y, 1.4, height * @order[:purchase_orders].length, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
      # self.txtb("#{@order[:part_id]}\n#{@order[:part_name].join("\n")}", 5.5, y, 1.85, height * (@order[:part_name].length + 1), size: 9, style: :bold, h_align: :left, h_pad: 0.05)
      # self.txtb(@order[:sub_id], 5.5, y, 1.85, height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
      # self.txtb(@order[:is_complete] ? "COMPLETE" : "PARTIAL", 9.95, y, 0.8, height, size: 9, style: :bold)

      # Format process specification.
      case @certification[:code]
      when "P8"
        @certification[:print_2nd_desc_after] = 99
        @certification[:omit_print_after] = 99
        @order[:process_specification] = [
          "PLATING: ELECTROLESS NICKEL",
          "PER ASTM B733 TYPE IV",
          "SERVICE CONDITION SC2 MODIFIED,",
          "CLASS 2 TYPE IV",
          "",
          "PLATING THICKNESS: 0.01 - 0.02 mm",
          "",
          "* STACK FOR PRESS BAKE *",
          "",
          "BAKE AFTER PLATING AT 385º +/- 15º C",
          "FOR 1 HOUR MINIMUM AT HEAT",
          "IN AN INERT ATMOSPHERE",
          "",
          "PLATING HARDNESS AFTER BAKE:",
          "HK<sub>100</sub> 806-935",
          "",
          "SURFACE HARDNESS OF FINISHED",
          "WASHER: HR30N 68-73",
          "HARDNESS TO BE CHECKED BY",
          "PENETRATING BOTH THE PLATING",
          "AND BASE METAL"
        ]
      when "S8"
        @certification[:print_2nd_desc_after] = 99
        @certification[:omit_print_after] = 99
        @order[:process_specification] = [
          "PLATING: ELECTROLESS NICKEL",
          "PER ASTM B733 TYPE IV",
          "SERVICE CONDITION SC2 MODIFIED,",
          "CLASS 2 TYPE IV",
          "",
          "PLATING THICKNESS: 0.01 - 0.02 mm",
          "",
          "BAKE AFTER PLATING AT 385º +/- 15º C",
          "FOR 1 HOUR MINIMUM AT HEAT",
          "IN AN INERT ATMOSPHERE",
          "",
          "PLATING HARDNESS AFTER BAKE:",
          "HK<sub>100</sub> 806-935",
          "",
          "SURFACE HARDNESS OF FINISHED",
          "WASHER: HR30N 68-73",
          "HARDNESS TO BE CHECKED BY",
          "PENETRATING BOTH THE PLATING",
          "AND BASE METAL"
        ]
      when "S3"
        @certification[:print_2nd_desc_after] = 99
        @certification[:omit_print_after] = 99
        @order[:process_specification] = [
          "PLATING: ELECTROLESS NICKEL",
          "PER ASTM B733 TYPE IV",
          "SERVICE CONDITION SC2 MODIFIED,",
          "CLASS 2 TYPE IV",
          "",
          "PLATING THICKNESS: 0.0004\" - 0.0006\"",
          "",
          "BAKE AFTER PLATING AT 385º +/- 15º C",
          "FOR 1 HOUR MINIMUM AT HEAT",
          "IN AN INERT ATMOSPHERE",
          "",
          "PLATING HARDNESS AFTER BAKE:",
          "HK<sub>100</sub> 806-935",
          "",
          "SURFACE HARDNESS OF FINISHED",
          "WASHER: HR30N 63 MINIMUM",
          "HARDNESS TO BE CHECKED BY",
          "PENETRATING BOTH THE PLATING",
          "AND BASE METAL"
        ]
      when "S4"
        @certification[:print_2nd_desc_after] = 99
        @certification[:omit_print_after] = 99
        @order[:process_specification] = [
          "PLATING: ELECTROLESS NICKEL",
          "PER ASTM B733 TYPE IV",
          "SERVICE CONDITION SC2 MODIFIED,",
          "CLASS 2 TYPE IV",
          "",
          "PLATING THICKNESS: 0.01mm - 0.015mm",
          "",
          "*** CLAMP & TEMPER ***",
          "",
          "BAKE AFTER PLATING AT 385º +/- 15º C",
          "FOR 1 HOUR MINIMUM AT HEAT",
          "IN AN INERT ATMOSPHERE",
          "",
          "PLATING HARDNESS AFTER BAKE:",
          "HK<sub>100</sub> 806-935",
          "",
          "SURFACE HARDNESS OF FINISHED",
          "WASHER: HR30N 63 MINIMUM",
          "HARDNESS TO BE CHECKED BY",
          "PENETRATING BOTH THE PLATING",
          "AND BASE METAL"
        ]
      when "SF"
        @certification[:print_2nd_desc_after] = 99
        @certification[:omit_print_after] = 99
        @order[:process_specification] = [
          "PLATING: ELECTROLESS NICKEL",
          "PER WSD-M1P65-B1",
          "",
          "PLATING THICKNESS: 0.015 +/- 0.005 mm",
          "",
          "BAKE AFTER PLATING AT 385º +/- 15º C",
          "FOR 1 HOUR MINIMUM AT HEAT",
          "IN AN INERT ATMOSPHERE",
          "",
          "PLATING HARDNESS AFTER BAKE:",
          "HK<sub>100</sub> 806-935",
          "",
          "SURFACE HARDNESS OF FINISHED",
          "WASHER: HR30N 63 MINIMUM",
          "HARDNESS TO BE CHECKED BY",
          "PENETRATING BOTH THE PLATING",
          "AND BASE METAL"
        ]
      end

      # Initialize position and line height.
      y = process_y
      height = 0.18

      # Initialize group indices for specification.
      group_1_start = 0
      group_1_end = (@certification[:print_1st_desc_before] == 0) ? -1 : @certification[:print_1st_desc_before]
      group_2_start = group_1_end + 1
      group_2_end = (@certification[:print_2nd_desc_after] == 0) ? ((@certification[:omit_print_after] == 0) ? 8 : @certification[:omit_print_after] - 1) : @certification[:print_2nd_desc_after] - 1
      group_3_start = group_2_end + 1
      group_3_end = (@certification[:omit_print_after] == 0) ? 8 : @certification[:omit_print_after] - 1;

      # Print part of process specification before first part of certification if necessary.
      data = false
      @order[:process_specification].each_with_index do |line, index|
        next if line.blank? || index < group_1_start || index > group_1_end
        self.txtb(line, process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
        data = true
      end
      y -= height if data

      # Print first part of specification.
      data = false
      @certification[:part_1].each do |line|
        next if line.blank?
        self.txtb(line, process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
        data = true
      end
      y -= height if data

      # Print part of process specification between first and second part of certification.
      data = false
      @order[:process_specification].each_with_index do |line, index|
        if line.blank? && ["S8", "S3", "SF", "P8", "S4"].include?(@certification[:code])
          y -= height * 0.5
          next
        end
        next if line.blank? || index < group_2_start || index > group_2_end
        self.txtb(line, process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
        data = true
      end
      y -= height if data

      # Print second part of specification.
      data = false
      case @certification[:code]
      when "01", "02", "04", "TI"
        y -= 2 * height
        sig_y = y
        y-= height * 0.5
        self.txtb("TIM HUDSON", process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
        self.txtb("QUALITY CONTROL MANAGER", process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
        self.txtb(ship_date, process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
        self.signature(:tim_hudson, process_x + 0.1, sig_y + 0.5, process_width - 0.2, 0.5, h_align: :left)
        self.hline(process_x + 0.05, sig_y, process_width - 0.1)
        data = true
      else
        @certification[:part_2].each do |line|
          next if line.blank?
          self.txtb(line, process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
          y -= height
          data = true
        end
      end
      y -= height if data

      # Print part of process specification after second part of certification.
      data = false
      @order[:process_specification].each_with_index do |line, index|
        next if line.blank? || index < group_3_start || index > group_3_end
        self.txtb(line, process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
        data = true
      end
      y -= height if data

      # Print third part of specification.
      @certification[:part_3].each do |line|
        next if line.blank?
        self.txtb(line, process_x, y, process_width, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
        y -= height
      end

      self.rect(process_x, process_y, process_width, process_y - y - height)

      return unless includes_thickness

      #return

      # Print thickness information if necessary.
      #return if @certification[:thickness_format] == "N" || @certification[:thickness_format].blank?

      # Count readings.
      reading_count = @order[:thickness_data][:readings].size

      # Draw boxes.
      #self.rect(thickness_x, thickness_y, check_number_width, height * reading_count)
      #self.rect(thickness_x + check_number_width, thickness_y, thickness_value_width, height * reading_count)
      #if has_alloy
      #  self.rect(thickness_x + check_number_width + thickness_value_width, thickness_y, thickness_value_width, height * reading_count)
      #end

      # Draw readings.
      y = thickness_y
      check_number_options = { size: 9, style: :bold, line_color: "000000" }
      thickness_options = { size: 9, style: :bold, h_align: :right, h_pad: 0.1, line_color: "000000" }
      @order[:thickness_data][:readings].each_with_index do |reading, index|
        self.txtb(index + 1, thickness_x, y, check_number_width, height, check_number_options)
        thickness_suffix =
          if @certification[:thickness_format] == "I"
            "\""
          else
            "µm"
          end
        thickness =
          if @certification[:thickness_format] == "I"
            self.format_number(reading[:thickness] / 1000, decimals: 6)
          else
            self.format_number(reading[:thickness] * 25.4, decimals: 3)
          end
        alloy = self.format_number(reading[:alloy], decimals: 3)
        if has_alloy
          self.txtb("#{thickness}#{thickness_suffix}", thickness_x + check_number_width, y, thickness_value_width, height, thickness_options)
          self.txtb("#{alloy}%", thickness_x + check_number_width + thickness_value_width, y, thickness_value_width, height, thickness_options)
        else
          self.txtb("#{thickness}#{thickness_suffix}", thickness_x + check_number_width, y, thickness_value_width, height, thickness_options)
        end
        y -= height
      end

    end

    # Draws certification format.
    def draw_certification_format

      # Draw letterhead graphics.
      path = Rails.root.join('lib', 'assets', 'letterhead', "portrait.png")
      self.image(path, at: [0.25.in, 10.75.in], width: 8.in, height: 1.25.in)

      # Draw footer graphics.
      self.standard_graphic('iso', 2.57, 0.75, 0.89, 0.5, h_align: :left)
      self.standard_graphic('itar', 3.71, 0.75, 1.57, 0.5, h_align: :left)
      self.qr_code("http://www.varland.com", 5.53, 0.75, 0.4, 0.4)
      self.txtb("varland.com", 5.53, 0.35, 0.4, 0.1, size: 4.75, style: :bold)

      # Draw title.
      self.txtb("PLATING CERTIFICATION", 0.25, 9.25, 8, 0.375, size: 33, style: :bold, font: "Gotham Condensed")

      # Draw boxes for part information.
      header_options = {line_color: '000000', fill_color: 'e3e3e3', size: 8}
      self.txtb("CUSTOMER", 0.25, 8.425, 2.5, 0.25, header_options)
      self.txtb("S.O. #", 2.75, 8.425, 0.75, 0.25, header_options)
      self.txtb("CUSTOMER PO #", 3.5, 8.425, 1.5, 0.25, header_options)
      self.txtb("PART DESCRIPTION", 5, 8.425, 1.85, 0.25, header_options)
      self.txtb("ORDER INFORMATION", 6.85, 8.425, 1.4, 0.25, header_options)

      return

      # Draw website QR code.
      self.qr_code("http://www.varland.com", 5.5, 7.925, 0.5, 0.5)
      self.txtb("varland.com", 5.5, 7.425, 0.5, 0.1, size: 6, style: :bold)

      # Print ship to and sold to labels.
      self.txtb("S\nO\nL\nD\n \nT\nO", 0.25, 6.75, 0.15, 1, v_align: :top, h_align: :center, size: 8)
      self.txtb("S\nH\nI\nP\n \nT\nO", 5.5, 6.75, 0.15, 1, v_align: :top, h_align: :center, size: 8)

      # Draw shipper number box.
      self.txtb("SHIPPER #", 9.75, 6.75, 1, 0.25, line_color: '000000', fill_color: 'e3e3e3', size: 8, style: :bold)

      # Draw box for certification.
      self.txtb("PLATING CERTIFICATION", 0.25, 5.5, 10.5, 0.5, line_color: "000000", size: 30, style: :bold)
      header_options = {line_color: '000000', fill_color: 'e3e3e3', size: 8}
      self.txtb("S.O. #", 0.25, 5, 0.6, 0.25, header_options)
      self.txtb("S.O. DATE", 0.85, 5, 0.75, 0.25, header_options)
      self.txtb("POUNDS", 1.6, 5, 0.75, 0.25, header_options)
      self.txtb("PIECES", 2.35, 5, 0.75, 0.25, header_options)
      self.txtb("CONTAINERS", 3.1, 5, 1, 0.25, header_options)
      self.txtb("CUSTOMER PO #", 4.1, 5, 1.4, 0.25, header_options)
      self.txtb("PART DESCRIPTION", 5.5, 5, 1.85, 0.25, header_options)
      self.txtb("PROCESS SPECIFICATION", 7.35, 5, 2.6, 0.25, header_options)
      self.txtb("STATUS", 9.95, 5, 0.8, 0.25, header_options)
      self.rect(0.25, 4.75, 0.6, 4)
      self.rect(0.85, 4.75, 0.75, 4)
      self.rect(1.6, 4.75, 0.75, 4)
      self.rect(2.35, 4.75, 0.75, 4)
      self.rect(3.1, 4.75, 1, 4)
      self.rect(4.1, 4.75, 1.4, 4)
      self.rect(5.5, 4.75, 1.85, 4)
      self.rect(7.35, 4.75, 2.6, 4)
      self.rect(9.95, 4.75, 0.8, 4)

      # Draw received by line.
      text = "Received By: "
      width = self.calc_width(text, size: 8)
      self.txtb(text, 0.25, 0.5, width, 0.25, v_align: :bottom, size: 8, h_align: :left)
      self.hline(0.25 + width, 0.25, 4)

    end

    # Draws shipper format.
    def draw_shipper_format

      # Draw format name.
      self.repeat(@vms_pages) do
        self.txtb("VMS PACKING LIST", 8.75, 8.25, 2, 0.25, v_align: :top, h_align: :right, size: 8)
      end
      self.repeat(@packing_list_pages) do
        self.txtb("PACKING LIST", 8.75, 8.25, 2, 0.25, v_align: :top, h_align: :right, size: 8)
      end

      # Print remaining format on all pages.
      self.repeat(@vms_pages + @packing_list_pages) do

        # Draw letterhead graphics.
        path = Rails.root.join('lib', 'assets', 'letterhead', "packing_list.png")
        self.image(path, at: [0.25.in, 8.25.in], width: 10.5.in, height: 1.25.in)

        # Draw website QR code.
        self.qr_code("http://www.varland.com", 5.5, 7.925, 0.5, 0.5)
        self.txtb("varland.com", 5.5, 7.425, 0.5, 0.1, size: 6, style: :bold)

        # Print ship to and sold to labels.
        self.txtb("S\nO\nL\nD\n \nT\nO", 0.25, 6.75, 0.15, 1, v_align: :top, h_align: :center, size: 8)
        self.txtb("S\nH\nI\nP\n \nT\nO", 5.5, 6.75, 0.15, 1, v_align: :top, h_align: :center, size: 8)

        # Draw shipper number box.
        self.txtb("SHIPPER #", 9.75, 6.75, 1, 0.25, line_color: '000000', fill_color: 'e3e3e3', size: 8, style: :bold)

        # Draw box for certification.
        header_options = {line_color: '000000', fill_color: 'e3e3e3', size: 8}
        self.txtb("S.O. #", 0.25, 5.5, 0.6, 0.25, header_options)
        self.txtb("S.O. DATE", 0.85, 5.5, 0.75, 0.25, header_options)
        self.txtb("POUNDS", 1.6, 5.5, 0.75, 0.25, header_options)
        self.txtb("PIECES", 2.35, 5.5, 0.75, 0.25, header_options)
        self.txtb("CONTAINERS", 3.1, 5.5, 1, 0.25, header_options)
        self.txtb("CUSTOMER PO #", 4.1, 5.5, 1.4, 0.25, header_options)
        self.txtb("PART DESCRIPTION", 5.5, 5.5, 1.85, 0.25, header_options)
        self.txtb("PROCESS SPECIFICATION", 7.35, 5.5, 2.6, 0.25, header_options)
        self.txtb("STATUS", 9.95, 5.5, 0.8, 0.25, header_options)
        self.rect(0.25, 5.25, 0.6, 4.5)
        self.rect(0.85, 5.25, 0.75, 4.5)
        self.rect(1.6, 5.25, 0.75, 4.5)
        self.rect(2.35, 5.25, 0.75, 4.5)
        self.rect(3.1, 5.25, 1, 4.5)
        self.rect(4.1, 5.25, 1.4, 4.5)
        self.rect(5.5, 5.25, 1.85, 4.5)
        self.rect(7.35, 5.25, 2.6, 4.5)
        self.rect(9.95, 5.25, 0.8, 4.5)

        # Draw received by line.
        text = "Received By: "
        width = self.calc_width(text, size: 8)
        self.txtb(text, 0.25, 0.5, width, 0.25, v_align: :bottom, size: 8, h_align: :left)
        self.hline(0.25 + width, 0.25, 4)

      end

    end

  end