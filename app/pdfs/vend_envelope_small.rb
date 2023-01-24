# Class for printing Vendor Address envelopes.
class VendEnvelopeSmall < VarlandPdf

  PAGE_SIZE = [4.125.in, 9.5.in]
  PAGE_ORIENTATION = :landscape

  # Constructor.
  def initialize(vendor)

    # Call parent constructor.
    super()

    # Load data.
    @vendor = vendor
    self.load_data

    # Create employee addresses.
    self.txtb("#{@data[:name]}\n#{@data[:street]}\n#{@data[:city]}, #{@data[:state]} #{@data[:zip]}", 0, 3.625, 9.5, 3.625, size: 24, font: "Gotham Condensed", style: :bold)

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://json400.varland.com/vendor_address?vendor=#{@vendor}")
  end

end