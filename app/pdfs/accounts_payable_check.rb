# Class for printing accounts payable checks from System i.
class AccountsPayableCheck < VarlandPdf

  # Default font family.
  DEFAULT_FONT_FAMILY = 'SF Mono'

  # Default font style.
  DEFAULT_FONT_STYLE = :bold
  
  # Constructor.
  def initialize(start_number, end_number)

    # Call parent constructor.
    super()

    # Load data.
    @start_number = start_number
    @end_number = end_number
    self.load_data

    # Print data.
    self.draw_data

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://json400.varland.com/reprint_checks?start_number=#{@start_number}&end_number=#{@end_number}")
  end

  # Prints data.
  def draw_data

    # Draw format for each check.
    @data[:checks].each_with_index do |check, index|

      # Start new page if necessary.
      self.start_new_page if index > 0

      # Draw vendor ID and name at top of check.
      self.txtb(check[:vendor][:id], 0.5, 10.5, 5, 0.25, h_align: :left, v_align: :top)
      self.txtb(check[:vendor][:name][0], 1.45, 10.5, 5, 0.25, h_align: :left, v_align: :top)

      # Draw remittance table headers.
      self.txtb("DATE", 0.25, 10.3, 0.85, 0.3, line_color: "000000", size: 8)
      self.txtb("INVOICE/REF", 1.1, 10.3, 1.1, 0.3, line_color: "000000", size: 8, h_align: :left, h_pad: 0.1)
      self.txtb("AMOUNT", 2.2, 10.3, 1.3, 0.3, line_color: "000000", size: 8)
      self.txtb("DISCOUNT", 3.5, 10.3, 1.3, 0.3, line_color: "000000", size: 8)
      self.txtb("NET", 4.8, 10.3, 1.3, 0.3, line_color: "000000", size: 8)
      self.txtb("DESCRIPTION", 6.1, 10.3, 2.15, 0.3, line_color: "000000", size: 8, h_align: :left, h_pad: 0.1)

      # Draw remittance table lines.
      [0.25, 1.1, 2.2, 3.5, 4.8, 6.1, 8.25].each do |x|
        self.vline(x, 10, 6)
      end
      self.hline(0.25, 4, 8)

      # Draw remittance table footer.
      self.txtb(Time.iso8601(check[:check_date]).strftime("%m/%d/%y"), 0.25, 4, 0.85, 0.3, h_pad: 0.05)
      self.txtb("TOTALS", 1.1, 4, 1.1, 0.3, line_color: "000000", size: 8, h_align: :left, h_pad: 0.1)
      self.txtb(self.format_number(check[:total_gross], decimals: 2), 2.2, 4, 1.3, 0.3, line_color: "000000", h_align: :right, h_pad: 0.1)
      if check[:total_discount] == 0
        self.rect(3.5, 4, 1.3, 0.3)
      else
        self.txtb(self.format_number(check[:total_discount], decimals: 2), 3.5, 4, 1.3, 0.3, line_color: "000000", h_align: :right, h_pad: 0.1)
      end
      self.txtb(self.format_number(check[:total_net], decimals: 2), 4.8, 4, 1.3, 0.3, line_color: "000000", h_align: :right, h_pad: 0.1)
      self.txtb("CHECK #", 6.1, 4, 2.15, 0.3, h_align: :left, h_pad: 0.1)
      self.txtb(check[:number], 6.1, 4, 2.15, 0.3, h_align: :right)

      # Draw remittance items.
      y = 10
      running_net = 0
      check[:items].each do |item|
        running_net += item[:net]
        self.txtb(Time.iso8601(item[:due_date]).strftime("%m/%d/%y"), 0.25, y, 0.85, 0.2, h_pad: 0.05)
        self.txtb(item[:open_item_invoice], 1.1, y, 1.1, 0.2, h_align: :left, h_pad: 0.1)
        self.txtb(self.format_number(item[:amount], decimals: 2), 2.2, y, 1.3, 0.2, h_align: :right, h_pad: 0.1)
        self.txtb(self.format_number(item[:discount], decimals: 2), 3.5, y, 1.3, 0.2, h_align: :right, h_pad: 0.1) unless item[:discount] == 0
        self.txtb(self.format_number(running_net, decimals: 2), 4.8, y, 1.3, 0.2, h_align: :right, h_pad: 0.1)
        self.txtb(item[:description], 6.1, y, 2.15, 0.2, h_align: :left, h_pad: 0.1)
        y -= 0.2
      end

      # Print mailing address.
      self.txtb("#{check[:vendor][:name].join("\n")}\n#{check[:vendor][:address]}\n#{check[:vendor][:city]} #{check[:vendor][:state]}\n#{check[:vendor][:zip]}", 1.15, 1.5, 6.2, 0.9, h_align: :left, v_align: :top)

      # Print text amount.
      self.txtb(check[:text_amount].upcase, 1, 2, 6.5, 0.2, h_align: :left, v_align: :top)

      # Print data line.
      self.txtb(check[:vendor][:code], 0.45, 2.42, 6, 0.2, h_align: :left, v_align: :top)
      self.txtb(check[:number], 3.25, 2.42, 6, 0.2, h_align: :left, v_align: :top)
      self.txtb(Time.iso8601(check[:check_date]).strftime("%m/%d/%y"), 4.3, 2.42, 1, 0.2, v_align: :top)
      self.txtb(check[:items][0][:voucher], 5.4, 2.42, 1.25, 0.2, v_align: :top) if check[:items].length == 1
      self.txtb("$#{check[:formatted_amount]}", 6.75, 2.42, 1.3, 0.2, h_align: :right, v_align: :top)

      # Print data header line.
      self.txtb("DATE", 4.3, 2.6, 1, 0.2, v_align: :top)
      self.txtb("VOUCHER #", 5.4, 2.6, 1.25, 0.2, v_align: :top) if check[:items].length == 1
      self.txtb("AMOUNT", 6.75, 2.6, 1.3, 0.2, h_align: :right, v_align: :top)

    end

  end

end