# Class for printing plating certification from System i.
class Certification < VarlandPdf

  # Default page orientation for Varland documents. May be overridden in child classes.
  PAGE_ORIENTATION = :landscape

  # Default letterhead format. May be overridden in child classes.
  LETTERHEAD_FORMAT = :packing_list

  # Constructor.
  def initialize

    # Call parent constructor.
    super

    # Draw standard format.
    self.draw_format

    # Load data.
    self.load_data

    # Draw data on certification.
    self.draw_data

  end

  # Loads certification data.
  def load_data
    path = Rails.root.join("lib", "assets", "sample_data", "shipper.json")
    file_data = File.read(path)
    @data = JSON.parse(file_data, symbolize_names: true)
  end

  # Draws data on certification.
  def draw_data

    # Print sold to and ship to.
    self.txtb("DIAMOND CHAIN CO.\n402 KENTUCKY AVE.\nINDIANAPOLIS, IN 46225", 0.5, 6.75, 3, 1, v_align: :top, h_align: :left, style: :bold)
    self.txtb("DIAMOND CHAIN CO.\n402 KENTUCKY AVE.\nINDIANAPOLIS, IN 46225", 5.75, 6.75, 3, 1, v_align: :top, h_align: :left, style: :bold)

    # Print shipper number.
    self.txtb(@data[:shipper], 9.75, 6.5, 1, 0.25, style: :bold, size: 16)

    # Print certification date, ship via, and vendor code.
    self.txtb("CERTIFICATION DATE: <b>#{Time.iso8601(@data[:orders][0][:ship_date]).strftime("%m/%d/%y")}</b>", 0.25, 5.27, 5.25, 0.25, v_align: :bottom, h_align: :left, size: 9)
    self.txtb("SHIP VIA: <b>#{@data[:how_shipped][:description]}</b>", 5.5, 5.27, 3, 0.25, v_align: :bottom, h_align: :left, size: 9)
    unless @data[:customer][:vendor_id].blank?
      self.txtb("<b>#{@data[:customer][:vendor_id]}</b>", 9.75, 5.27, 1, 0.25, v_align: :bottom, h_align: :right, size: 9)
    end

    # Print data.
    y = 3.98
    height = 0.15
    self.txtb("299855", 0.25, y, 0.6, height, size: 9, style: :bold)
    self.txtb("09/17/19", 0.85, y, 0.75, height, size: 9, style: :bold)
    self.txtb("70.00", 1.6, y, 0.75, height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
    self.txtb("34,535", 2.35, y, 0.75, height, size: 9, style: :bold, h_align: :right, h_pad: 0.05)
    self.txtb("1 BUCKET", 3.1, y, 1, height, size: 9, style: :bold)
    self.txtb("82891", 4.1, y, 1.4, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    self.txtb("ZN-1282AG", 5.5, y, 1.85, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    self.txtb("WE CERTIFY THAT THIS LOT OF PARTS", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    self.txtb("COMPLETE", 9.95, y, 0.8, height, size: 9, style: :bold)
    y -= height
    self.txtb("35ZN RIVITED PIN", 5.5, y, 1.85, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    self.txtb("WAS PROCESSED TO THE FOLLOWING", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= height
    self.txtb("PARAMETERS:", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= 2 * height
    self.txtb("ZINC-NICKEL (.00015\" - 0.003\")", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= height
    self.txtb("BAKE @ 265º F - 320º F FOR 8 HRS", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= height
    self.txtb("& CLEAR TRIVALENT CHROMATE", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= height
    self.txtb("PLUS ORGANIC TOPCOAT", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= height
    self.txtb("PROCESS SPECIFICATION 12516", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= 3 * height
    self.signature(:greg_turner, 7.4, y + 0.3, 2.5, 0.3, h_align: :left, baseline_shift: -0.06)
    self.hline(7.4, y, 2.5)
    self.txtb("GREG TURNER", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= height
    self.txtb("QUALITY CONTROL MANAGER", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)
    y -= height
    self.txtb("09/24/19", 7.35, y, 2.6, height, size: 9, style: :bold, h_align: :left, h_pad: 0.05)

  end

  # Draws standard format.
  def draw_format

    # Print ship to and sold to labels.
    self.txtb("S\nO\nL\nD\n \nT\nO", 0.25, 6.75, 0.15, 1, v_align: :top, h_align: :center, size: 8)
    self.txtb("S\nH\nI\nP\n \nT\nO", 5.5, 6.75, 0.15, 1, v_align: :top, h_align: :center, size: 8)

    # Draw shipper number box.
    self.txtb("SHIPPER #", 9.75, 6.75, 1, 0.25, line_color: '000000', fill_color: 'dddddd', size: 8, style: :bold)

    # Draw box for certification.
    self.txtb("PLATING CERTIFICATION", 0.25, 5, 10.5, 0.75, line_color: "000000", size: 30, style: :bold)
    header_options = {line_color: '000000', fill_color: 'dddddd', size: 8}
    self.txtb("S.O. #", 0.25, 4.25, 0.6, 0.25, header_options)
    self.txtb("S.O. DATE", 0.85, 4.25, 0.75, 0.25, header_options)
    self.txtb("POUNDS", 1.6, 4.25, 0.75, 0.25, header_options)
    self.txtb("PIECES", 2.35, 4.25, 0.75, 0.25, header_options)
    self.txtb("CONTAINERS", 3.1, 4.25, 1, 0.25, header_options)
    self.txtb("CUSTOMER PO #", 4.1, 4.25, 1.4, 0.25, header_options)
    self.txtb("PART DESCRIPTION", 5.5, 4.25, 1.85, 0.25, header_options)
    self.txtb("PROCESS SPECIFICATION", 7.35, 4.25, 2.6, 0.25, header_options)
    self.txtb("STATUS", 9.95, 4.25, 0.8, 0.25, header_options)
    self.rect(0.25, 4, 0.6, 3.25)
    self.rect(0.85, 4, 0.75, 3.25)
    self.rect(1.6, 4, 0.75, 3.25)
    self.rect(2.35, 4, 0.75, 3.25)
    self.rect(3.1, 4, 1, 3.25)
    self.rect(4.1, 4, 1.4, 3.25)
    self.rect(5.5, 4, 1.85, 3.25)
    self.rect(7.35, 4, 2.6, 3.25)
    self.rect(9.95, 4, 0.8, 3.25)

    # Draw received by line.
    text = "Received By: "
    width = self.calcwidth(text, size: 8)
    self.txtb(text, 0.25, 0.5, width, 0.25, v_align: :bottom, size: 8, h_align: :left)
    self.hline(0.25 + width, 0.25, 4)

  end

end