# Class for demonstrating capabilities of VarlandPDF class.
class Sample < VarlandPdf

  # Constructor.
  def initialize

    # Call parent constructor.
    super()

    # Sample logo.
    self.logo(0.25, 10.75, 8, 1, variant: :stacked, h_align: :left, v_align: :center)

    # Sample signature & rectangles.
    self.rect(4.75, 10.75, 3.5, 1)
    self.rect(4.95, 10.5, 3.1, 0.5, line_color: nil, fill_color: 'ffffcc')
    self.hline(4.95, 10, 3.1)
    self.txtb('Signature', 4.95, 10, 3.1, 0.25, size: 8, font: 'Whitney Index Squared')
    self.signature(:tim_hudson, 4.95, 10.65, 3.1, 0.65, baseline_shift: -0.25)
    #self.signature(:toby_varland, 4.95, 10.65, 3.1, 0.65, baseline_shift: -0.05)
    #self.signature(:terry_marshall, 4.95, 10.65, 3.1, 0.65, baseline_shift: -0.175)
    #self.signature(:rob_caudill, 4.95, 10.65, 3.1, 0.65, baseline_shift: -0.075)

    # Sample lines.
    self.hline(0.35, 9.5, 7.8, line_color: 'ff0000', line_width: 0.1)
    self.hline(0.35, 8.5, 7.8, line_color: '00ff00', line_width: 0.1)
    self.vline(0.25, 9.4, 0.8, line_color: '0000ff', line_width: 0.1)
    self.vline(8.25, 9.4, 0.8, line_color: 'ffff00', line_width: 0.1)

    # Sample barcode.
    self.barcode(299944.to_s.rjust(10), 3, 9.25, 2.5, 0.5, fill_color: 'dddddd')

    # Sample QR code.
    self.qr_code('http://www.varland.com', 7.25, 5.75, 1, 1)

    # Sample text box.
    self.txtb("This is a sample text box. Formatting options include <b>bold</b>, <i>italics</i>, <u>underline</u>, <strikethrough>strike through</strikethrough>, <sup>superscript</sup>, and <sub>subscript</sub>. You can also modify the <font name='Whitney Index Rounded'>font name</font>, <font size='8'>font size</font>, and <font character_spacing='4'>character spacing</font>. You can do inline <color rgb='0000ff'>color</color> formatting. Finally, you can add <color rgb='0000ff'><u><link href='http://www.varland.com'>links</link></u></color>.", 0.25, 8.25, 8, 1)

    # Sample text box.
    self.txtb("You can pass rectangle parameters to text boxes to include a border or shading. You can include <code>fill_color</code>, <code>line_color</code>, and <code>line_width</code>.", 0.25, 7, 8, 1, fill_color: 'cccccc', line_color: '000000', line_width: 0.05)

    # Sample table.
    self.table(0.25,
               5.75,
               [2, 2],
               5,
               0.25,
               header_row: true,
               row_colors: ['ffffff', 'edf3fe'],
               headers: ['Column 1', 'Column 2'],
               headers_h_align: [:center, :center],
               data: [['String', 5.526], ['String', 2.572]],
               data_h_align: [:center, :right],
               data_format_codes: ['%s', '$%.2f'])

  end

end