# Class for printing Employee Address envelopes.
class EmployeeEnvelopesSmall < VarlandPdf

  PAGE_SIZE = [4.125.in, 9.5.in]
  PAGE_ORIENTATION = :landscape

  # Constructor.
  def initialize

    # Call parent constructor.
    super()

    # Load data.
    self.load_data

    # Create employee addresses.
    @data.each_with_index do |employee, index|
      self.start_new_page if index > 0
      self.txtb("#{employee[:name]}\n#{employee[:street]}\n#{employee[:city]}, #{employee[:state]} #{employee[:zip]}", 0, 3.625, 9.5, 3.625, size: 24, font: "Gotham Condensed", style: :bold)
    end

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://json400.varland.com/employee_addresses")
  end

end