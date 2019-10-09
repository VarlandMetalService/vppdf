# Class for demonstrating capabilities of VarlandPDF class.
class Sample < VarlandPdf

  # Constructor.
  def initialize

    # Call parent constructor.
    super

    # Call function to draw format.
    self.draw_format

  end

  # Function to draw format.
  def draw_format

    # Sample logo.
    self.logo(0.25, 10.75, 3, 1, variant: :stacked, h_align: :center, v_align: :center, fill_color: '000000', invert_colors: true, mono: false)

    # Sample signature & rectangles.
    self.rect(4.75, 10.75, 3.5, 1)
    self.rect(4.95, 10.5, 3.1, 0.5, line_color: nil, fill_color: 'ffffcc')
    self.hline(4.95, 10, 3.1)
    self.txtb('Signature', 4.95, 10, 3.1, 0.25, size: 8, font: 'Whitney Index Squared')
    self.signature(:toby_varland, 4.95, 10.65, 3.1, 0.65)

    # Sample lines.
    self.hline(0.35, 9.5, 7.8, line_color: 'ff0000', line_width: 0.1)
    self.hline(0.35, 8.5, 7.8, line_color: '00ff00', line_width: 0.1)
    self.vline(0.25, 9.4, 0.8, line_color: '0000ff', line_width: 0.1)
    self.vline(8.25, 9.4, 0.8, line_color: 'ffff00', line_width: 0.1)

    # Sample barcode.
    self.barcode(299944.to_s.rjust(10), 3, 9.25, 2.5, 0.5)

    # Sample QR code.
    self.qr_code('http://www.varland.com', 7.25, 5.75, 1, 1)

    # Standard graphic.
    self.standard_graphic(:state_seal, 0.25, 4, 2.5, 1, h_align: :left)
    self.standard_graphic(:itar, 3, 4, 2.5, 1, h_align: :center)
    self.standard_graphic(:iso, 5.75, 3.85, 2.5, 0.7, h_align: :right)

    # Sample text box.
    self.txtb("This is a sample text box. Formatting options include <b>bold</b>, <i>italics</i>, <u>underline</u>, <strikethrough>strike through</strikethrough>, <sup>superscript</sup>, and <sub>subscript</sub>.\nYou can also modify the <font name='Whitney Index Rounded'>font name</font>, <font size='8'>font size</font>, and <font character_spacing='4'>character spacing</font>.\nYou can do inline <color rgb='0000ff'>color</color> formatting.\nFinally, you can add <color rgb='0000ff'><u><link href='http://www.varland.com'>links</link></u></color>.", 0.25, 8.25, 8, 1)

    # Sample text box.
    self.txtb("You can pass rectangle parameters to text boxes to include a border or shading.\nYou can include <code>fill_color</code>, <code>line_color</code>, and <code>line_width</code>.", 0.25, 7, 8, 1, fill_color: 'cccccc', line_color: '000000', line_width: 0.05)

    # Sample table.
    table = DataTable.new(x: 0.25,
                          y: 5.75,
                          width: 8,
                          height: 5.5,
                          column_widths: [5, 1, 1, 1],
                          headers: ['Normal', 'Binary', 'Hex', 'Currency'],
                          headers_h_align: [:left, :center, :center, :center],
                          header_font: 'Whitney Bold',
                          rows_h_align: [:left, :right, :right, :right],
                          rows_format: ['%s', '%b', '%x', '$%.2f'],
                          row_bg_colors: ['edf3fe', 'ffffff'])
    (1..4).each do |i|
      table.rows << [i, i, i, i]
    end
    table.draw(self)

  end

end