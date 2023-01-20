# Class for printing Employee Address envelopes.
class EmployeeLabels < VarlandPdf

  # Constructor.
  def initialize

    # Call parent constructor.
    super()

    # Load data.
    self.load_data

    # Create employee addresses.
    label_number = 0
    gutter = (5.0 / 32.0)
    width = 2.625
    height = 1.0
    @data.each_with_index do |employee, index|
      label_number += 1
      if label_number > 30
        self.start_new_page
        label_number = 1
      end
      x = case label_number
          when 1..10 then gutter
          when 11..20 then width + 2 * gutter
          when 21..30 then 2 * width + 3 * gutter
          end
      y = 10.5 - ((label_number - 1) % 10) * height
      self.txtb("#{employee[:name]}\n#{employee[:street]}\n#{employee[:city]}, #{employee[:state]} #{employee[:zip]}", x, y, width, height, size: 14, font: "Gotham Condensed", style: :bold)
    end

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://json400.varland.com/employee_addresses")
  end

end