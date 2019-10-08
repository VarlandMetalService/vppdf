# Class for demonstrating signature fonts.
class SignatureSampler < VarlandPdf

  # Constructor.
  def initialize(name)

    # Call parent constructor.
    super()

    # Store name.
    @name = name.blank? ? "First Last" : name

    # Call function to draw format.
    self.draw_format

  end

  # Function to draw format.
  def draw_format

    # Define signature font names.
    names = [
      'Across The Road',
      'Alabama',
      'Arty Signature',
      'Asem Kandis',
      'Autograf',
      'Born Ready',
      'Brittany Signature',
      'Bulgatti',
      'Estelly',
      'Friday Vibes',
      'From Skyler',
      'Gallatone',
      'Halimun',
      'Hello Santtiny',
      'Just Realize',
      'Just Signature',
      'Mayestica',
      'Notera',
      'Prestige Signature',
      'Reinata',
      'Santos Dumont',
      'Shopping List',
      'Signatures',
      'Signerica',
      'Silver Pen',
      'Sophistica',
      'Southampton',
      'Thankfully',
      'The Jacklyn',
      'Tomatoes',
      'Wanted Signature',
      'White Angelica',
      'Xtreem',
    ]

    # Draw boxes.
    @alt = false
    [0.25, 3, 5.75].each_with_index do |x, i|
      (1..11).each_with_index do |y, j|
        name_index = i * 11 + j
        self.draw_box(x, 12 - y, names[name_index], name_index)
      end
    end

  end

  # Draws signature box.
  def draw_box(x, y, font, index)

    # Define total width and height.
    width = 2.5
    height = 1
    name_height = 0.1
    default_buffer = 0.1

    # Draw font name.
    self.txtb(font,
              x + default_buffer,
              y - default_buffer,
              width - 2 * default_buffer,
              name_height,
              h_align: :left,
              v_align: :top,
              style: :bold,
              size: 6)

    # Draw outline box.
    self.rect(x + default_buffer,
              y - name_height - default_buffer,
              width - 2 * default_buffer,
              height - name_height - 2 * default_buffer,
              line_width: 0.0075)

    # Shade signature box.
    sig_box_height = height - name_height - 4 * default_buffer
    sig_box_y = y - name_height - 2 * default_buffer
    # self.rect(x + 2 * default_buffer,
    #           sig_box_y,
    #           width - 4 * default_buffer,
    #           sig_box_height,
    #           line_color: nil,
    #           fill_color: 'ffffcc')

    # Draw signature line.
    self.hline(x + 2 * default_buffer,
               y - height + 2 * default_buffer,
               width - 4 * default_buffer,
               line_width: 0.005)

    # Get font properties.
    font_size = sig_box_height * self.default_size_multiplier(font)
    baseline_shift = self.default_signature_shift(font, font_size)

    # Draw text.
    self.txtb(@name,
              x + 2 * default_buffer,
              sig_box_y + baseline_shift,
              width - 4 * default_buffer,
              sig_box_height,
              v_align: :bottom,
              color: '0000ff',
              size: font_size.in,
              font: font)

  end

end