# Class for bakesheets.
class Bakesheet < VarlandPdf

  # Constructor.
  def initialize

    # Call parent constructor.
    super()

    # Call function to draw format.
    self.draw_format()

  end

  # Function to draw format.
  def draw_format

    # Draw logo and title.
    self.form_title("Bakesheet", 0.25, 10.75)

    # Draw table for baking parameters.
    self.txtb("Oven", 1.25, 10, 1, 0.25, line_color: '000000', fill_color: 'cccccc', size: 10, style: :bold, line_width: 0.015)
    self.txtb("Bakestand", 2.25, 10, 1, 0.25, line_color: '000000', fill_color: 'cccccc', size: 10, style: :bold, line_width: 0.015)
    self.txtb("Set (º F)", 3.25, 10, 1, 0.25, line_color: '000000', fill_color: 'cccccc', size: 10, style: :bold, line_width: 0.015)
    self.txtb("Min (º F)", 4.25, 10, 1, 0.25, line_color: '000000', fill_color: 'cccccc', size: 10, style: :bold, line_width: 0.015)
    self.txtb("Max (º F)", 5.25, 10, 1, 0.25, line_color: '000000', fill_color: 'cccccc', size: 10, style: :bold, line_width: 0.015)
    self.txtb("Hours", 6.25, 10, 1, 0.25, line_color: '000000', fill_color: 'cccccc', size: 10, style: :bold, line_width: 0.015)
    self.rect(1.25, 9.75, 1, 0.5, fill_color: 'ffffcc', line_width: 0.015)
    self.rect(2.25, 9.75, 1, 0.5, line_width: 0.015)
    self.rect(3.25, 9.75, 1, 0.5, line_width: 0.015)
    self.rect(4.25, 9.75, 1, 0.5, line_width: 0.015)
    self.rect(5.25, 9.75, 1, 0.5, line_width: 0.015)
    self.rect(6.25, 9.75, 1, 0.5, line_width: 0.015)

    # Draw text fields under table.
    text_width = self.calcwidth("Date/Time Out of Plating:", size: 10, style: :bold) 
    self.txtb("Date/Time Out of Plating:", 1.25, 9.25, text_width, 0.5, size: 10, style: :bold, h_align: :right, v_align: :bottom)
    self.txtb("Put In Oven By:", 1.25, 8.75, text_width, 0.5, size: 10, style: :bold, h_align: :right, v_align: :bottom)
    self.rect(1.25 + text_width + 0.05, 9.05, 5.95 - text_width, 0.3, fill_color: 'ffffcc', line_color: nil)
    self.rect(1.25 + text_width + 0.05, 8.55, 5.95 - text_width, 0.3, fill_color: 'ffffcc', line_color: nil)
    self.hline(1.25 + text_width + 0.05, 8.75, 5.95 - text_width)
    self.hline(1.25 + text_width + 0.05, 8.25, 5.95 - text_width)

    # Draw shop orders table.
    column_widths = [1, 3.25, 0.75, 0.75, 0.75, 0.75, 0.75]
    column_headings = ["S.O. #", "Part", "Set\n(º F)", "Min\n(º F)", "Max\n(º F)", "Hours", "Within\n(Hours)"]
    column_alignments = [:center, :left, :center, :center, :center, :center, :center]
    column_paddings = [0, 0.1, 0, 0, 0, 0, 0]
    x = 0.25
    column_headings.each_with_index do |text, index|
      self.txtb(text,
                x,
                7.75,
                column_widths[index],
                0.5,
                line_color: '000000',
                fill_color: 'cccccc',
                size: 10,
                style: :bold,
                line_width: 0.015,
                h_align: column_alignments[index],
                h_pad: column_paddings[index])
      x += column_widths[index]
    end
    y = 7.25
    (1..10).each do |row|
      x = 0.25
      column_widths.each do |width|
        self.rect(x, y, width, 0.3, line_width: 0.015)
        x += width
      end
      y -= 0.3
    end

    # Draw bakestand diagram.
    y = 3.75
    rows = 11
    columns = 4
    tray_width = 1.5
    tray_height = 0.3
    total_width = columns * tray_width
    x = 0.25 + ((8 - total_width) / 2)
    1.upto(columns) do |c|
      1.upto(rows) do |r|
        tray_x = x + ((c - 1) * tray_width)
        tray_y = y - ((r - 1) * tray_height)
        if r == 1
          self.txtb("DO NOT USE",
                    tray_x,
                    tray_y,
                    tray_width,
                    tray_height,
                    fill_color: 'cccccc',
                    line_color: '000000',
                    line_width: 0.015,
                    style: :bold,
                    color: '999999',
                    size: 6)
        else
          self.rect(tray_x, tray_y, tray_width, tray_height)
        end
      end
    end
    y -= rows * tray_height
    self.txtb("VIEW FROM LOADING SIDE OF BAKESTAND",
              0.25,
              y,
              8,
              0.2,
              style: :bold,
              size: 7,
              v_align: :top,
              v_pad: 0.05)

  end

end