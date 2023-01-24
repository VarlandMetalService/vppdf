# Class for printing Vendor Address envelope.
class VendEnvelope < VarlandPdf

  PAGE_SIZE = [9.in, 12.in]
  PAGE_ORIENTATION = :landscape

  # Constructor.
  def initialize(vendor)

    # Call parent constructor.
    super()

    # Load data.
    @vendor = vendor
    self.load_data

    # Create employee addresses.
    self.logo(0.25, 8.75, 11.5, 0.5, h_align: :left, variant: :mark, mono: true)
    self.txtb("VARLAND PLATING\n3231 FREDONIA AVE\nCINCINNATI, OH 45229", 0.8, 8.75, 8, 0.5, size: 18, font: "Gotham Condensed", style: :bold, h_align: :left)
    self.txtb("#{@data[:name]}\n#{@data[:street]}\n#{@data[:city]}, #{@data[:state]} #{@data[:zip]}", 0, 8, 12, 8, size: 24, font: "Gotham Condensed", style: :bold)

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://json400.varland.com/vendor_address?vendor=#{@vendor}")
  end

end