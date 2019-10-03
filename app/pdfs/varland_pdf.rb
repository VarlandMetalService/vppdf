# Load dependencies.
require 'prawn/measurement_extensions'
require 'barby'
require 'barby/barcode'
require 'barby/barcode/code_39'
require 'barby/barcode/qr_code'
require 'barby/outputter/prawn_outputter'
require 'barby/outputter/png_outputter'
require 'tempfile'
require 'fastimage'

# Parent class for all Varland PDFs. Defines common functions.
class VarlandPdf < Prawn::Document

  # Default margin for Varland documents. May be overridden in child classes.
  PAGE_MARGIN = 0.in

  # Default page orientation for Varland documents. May be overridden in child classes.
  PAGE_ORIENTATION = :portrait

  # Default letterhead format. May be overridden in child classes.
  LETTERHEAD_FORMAT = :none

  # Default color for lines. May be overridden in child classes.
  DEFAULT_LINE_COLOR = '000000'

  # Default font family. May be overridden in child classes.
  DEFAULT_FONT_FAMILY = 'Helvetica'

  # Default font size. May be overridden in child classes.
  DEFAULT_FONT_SIZE = 10

  # Default font style. May be overridden in child classes.
  DEFAULT_FONT_STYLE = :normal

  # Default color for text. May be overridden in child classes.
  DEFAULT_FONT_COLOR = '000000'

  # Default header fill color. May be overridden in child classes.
  DEFAULT_HEADER_FILL_COLOR = 'cccccc'

  # Constructor. Initializes Prawn document and loads custom font files.
  def initialize

    # Initialize Prawn document.
    super(top_margin: self.class::PAGE_MARGIN,
          bottom_margin: self.class::PAGE_MARGIN,
          left_margin: self.class::PAGE_MARGIN,
          right_margin: self.class::PAGE_MARGIN,
          page_layout: self.class::PAGE_ORIENTATION)
    
    # Load fonts.
    self.load_fonts

  end

  # Intercept render method for drawing letterhead graphics.
  def render()

    # Determine letterhead properties.
    path = nil
    x = nil
    y = nil
    width = nil
    height = 1.25
    case self.class::LETTERHEAD_FORMAT
    when :portrait
      path = Rails.root.join('lib', 'assets', 'letterhead', "portrait.png")
      x = 0.25
      y = 10.75
      width = 8
    when :landscape
      path = Rails.root.join('lib', 'assets', 'letterhead', "landscape.png")
      x = 0.25
      y = 8.25
      width = 10.5
    when :packing_list
      path = Rails.root.join('lib', 'assets', 'letterhead', "packing_list.png")
      x = 0.25
      y = 8.25
      width = 10.5
    end

    # Draw graphic on each page if necessary.
    if path
      self.repeat(:all) do
        self.image(path, at: [x.in, y.in], width: width.in, height: height.in)
      end
    end

    # Call parent render.
    super

  end

  # Loads fonts. Uses Prawn's font_families.update method to add new fonts.
  def load_fonts

    # Load fonts.
    self.load_single_font('Arial')
    self.load_single_font('Arial Narrow')
    self.load_single_font('Courier New')
    self.load_single_font('Menlo')
    self.load_single_font('SF Mono')
    self.load_single_font('Source Code Pro')
    self.load_single_font('Whitney')
    self.load_single_font('Whitney Bold')
    self.load_single_font('Whitney Index Rounded')
    self.load_single_font('Whitney Index Squared')

  end

  # Loads single font using Prawn's font_families.update method.
  def load_single_font(name)
    
    # Determine path to font file.
    font_file_name = name.gsub(/\s+/, "")
    path = Rails.root.join('lib', 'assets', 'fonts', "#{font_file_name}.ttf")
    return unless File.file?(path)

    # Determine variants.
    italics_path = Rails.root.join('lib', 'assets', 'fonts', "#{font_file_name}-Italic.ttf")
    bold_path = Rails.root.join('lib', 'assets', 'fonts', "#{font_file_name}-Bold.ttf")
    bold_italics_path = Rails.root.join('lib', 'assets', 'fonts', "#{font_file_name}-BoldItalic.ttf")

    # Build hash of variants.
    font_hash = { normal: path }
    font_hash[:italic] = italics_path if File.file?(italics_path)
    font_hash[:bold] = bold_path if File.file?(bold_path)
    font_hash[:bold_italic] = bold_italics_path if File.file?(bold_italics_path)

    # Add font.
    self.font_families.update(name => font_hash)

  end

  # Saves current properties.
  def save_current_properties
    @save_fill_color = self.fill_color
    @save_stroke_color = self.stroke_color
    @save_line_width = self.line_width
  end

  # Restores saved properties.
  def restore_saved_properties
    self.fill_color(@save_fill_color)
    self.stroke_color(@save_stroke_color)
    self.line_width = @save_line_width
  end

  # Parses text for custom formatting codes.
  def apply_custom_formatting(text)

    # Define custom formatting codes and replacement values.
    codes = []
    codes << '<code>'
    codes << '</code>'
    replacements = []
    replacements << '<font name="SF Mono"><color rgb="e83e8c"><b>'
    replacements << '</b></color></font>'

    # Process each replacement.
    codes.each_with_index do |code, index|
      text.gsub!(code, replacements[index])
    end

  end

  # Draws form title.
  def form_title(text, x, y)

    # Draw logo and title.
    logo_ratio = 13.0 / 15.0
    logo_height = 0.5
    logo_width = logo_height * logo_ratio
    self.logo(x, y, logo_width, logo_height, variant: :mark, h_align: :center, v_align: :center)
    self.txtb(text, x + 0.1 + logo_width, y, 8, 0.5, font: 'Whitney', h_align: :left, style: :bold, size: 20)

  end

  # Draws standard graphic.
  def standard_graphic(graphic, x, y, width, height, options = {})

    # Exit if no graphic passed.
    return if graphic.blank?

    # Load passed options or fall back to defaults.
    h_align = options.fetch(:h_align, :center)
    v_align = options.fetch(:v_align, :center)
    fill_color = options.fetch(:fill_color, nil)

    # Determine if graphic file exists. Return error if not.
    path = Rails.root.join('lib', 'assets', 'standard_graphics', "#{graphic.to_s}.png")
    unless File.file?(path)
      self.txtb("Graphic Error: #{graphic.to_s}", x, y, width, height, fill_color: 'ff0000', color: 'ffffff', style: :bold)
      return
    end
    
    # Shade area.
    self.rect(x, y, width, height, fill_color: fill_color, line_color: nil)

    # Read image dimensions.
    image_width, image_height = FastImage.size(path)

    # Calculate ratio.
    graphic_ratio = image_height.to_f / image_width.to_f

    # Calculate actual height and width.
    graphic_width = width
    graphic_height = graphic_ratio * graphic_width
    if graphic_height > height
      graphic_height = height
      graphic_width = graphic_height / graphic_ratio
    end

    # Calculate position.
    x_buffer = width - graphic_width
    y_buffer = height - graphic_height
    case h_align
    when :left
      x_buffer_multiplier = 0
    when :center
      x_buffer_multiplier = 0.5
    when :right
      x_buffer_multiplier = 1
    end
    case v_align
    when :top
      y_buffer_multiplier = 0
    when :center
      y_buffer_multiplier = 0.5
    when :bottom
      y_buffer_multiplier = 1
    end
    graphic_x = x + x_buffer_multiplier * x_buffer
    graphic_y = y - y_buffer_multiplier * y_buffer

    # Draw graphic.
    self.image(path, at: [graphic_x.in, graphic_y.in], width: graphic_width.in, height: graphic_height.in)

  end

  # Draws QR code.
  def qr_code(text, x, y, width, height, options = {})

    # Exit if no text passed.
    return if text.blank?

    # Generate barcode.
    code = Barby::QrCode.new(text.to_s)

    # Save PNG file.
    png_file = Tempfile.new(['qr', '.png'])
    png_file.binmode()
    png_file.write(code.to_png(margin: 0))
    png_file.close()

    # Draw QR code on PDF.
    self.image(png_file.path, at: [x.in, y.in], width: width.in, height: height.in)

    # Delete tempfile.
    png_file.unlink()

  end

  # Draws barcode.
  def barcode(text, x, y, width, height, options = {})

    # Exit if no text passed.
    return if text.blank?

    # Generate barcode.
    code = Barby::Code39.new(text.to_s)

    # Save PNG file.
    png_file = Tempfile.new(['barcode', '.png'])
    png_file.binmode()
    png_file.write(code.to_png(margin: 0))
    png_file.close()
    png_width, png_height = FastImage.size(png_file.path)

    # Draw barcode.
    self.image(png_file.path, at: [x.in, y.in], width: width.in, height: height.in)

    # Delete tempfile.
    png_file.unlink()

  end

  # Draws rectangle.
  def rect(x, y, width, height, options = {})
    self.save_current_properties()
    line_color = options.fetch(:line_color, self.class::DEFAULT_LINE_COLOR)
    fill_color = options.fetch(:fill_color, nil)
    unless fill_color.blank?
      self.fill_color(fill_color)
      self.fill_rectangle([x.in, y.in], width.in, height.in)
    end
    unless line_color.blank?
      self.stroke_color(line_color)
      self.line_width = options[:line_width].in if options.key?(:line_width) && !options[:line_width].blank?
      self.stroke_rectangle([x.in, y.in], width.in, height.in)
    end
    self.restore_saved_properties()
  end

  # Draws horizontal line.
  def hline(x, y, length, options = {})
    line_color = options.fetch(:line_color, self.class::DEFAULT_LINE_COLOR)
    return if line_color.blank?
    self.save_current_properties()
    self.stroke_color(line_color)
    self.line_width = options[:line_width].in if options.key?(:line_width) && !options[:line_width].blank?
    self.stroke_line([x.in, y.in], [(x + length).in, y.in])
    self.restore_saved_properties()
  end

  # Draws vertical line.
  def vline(x, y, length, options = {})
    line_color = options.fetch(:line_color, self.class::DEFAULT_LINE_COLOR)
    return if line_color.blank?
    self.save_current_properties()
    self.stroke_color(line_color)
    self.line_width = options[:line_width].in if options.key?(:line_width) && !options[:line_width].blank?
    self.stroke_line([x.in, y.in], [x.in, (y - length).in])
    self.restore_saved_properties()
  end

  # Calculates width of given text.
  def calcwidth(text, options = {})
    return 0 if text.blank?
    font_family = options.fetch(:font, self.class::DEFAULT_FONT_FAMILY)
    font_style = options.fetch(:style, self.class::DEFAULT_FONT_STYLE)
    font_size = options.fetch(:size, self.class::DEFAULT_FONT_SIZE)
    self.font(font_family, style: font_style)
    return self.width_of(text.to_s, size: font_size) / 72.0
  end

  # Draws text box.
  def txtb(text, x, y, width, height, options = {})

    # Exit if no text passed.
    return if text.blank?

    # Convert passed text to string.
    text = text.to_s

    # Apply custom formatting to text.
    self.apply_custom_formatting(text)

    # Load passed options or fall back to defaults.
    fill_color = options.fetch(:fill_color, nil)
    line_color = options.fetch(:line_color, nil)
    line_width = options.fetch(:line_width, nil)
    font_family = options.fetch(:font, self.class::DEFAULT_FONT_FAMILY)
    font_style = options.fetch(:style, self.class::DEFAULT_FONT_STYLE)
    font_size = options.fetch(:size, self.class::DEFAULT_FONT_SIZE)
    font_color = options.fetch(:color, self.class::DEFAULT_FONT_COLOR)
    h_align = options.fetch(:h_align, :center)
    v_align = options.fetch(:v_align, :center)
    h_pad = options.fetch(:h_pad, 0)
    v_pad = options.fetch(:v_pad, 0)

    # If stroke/fill options passed, draw rectangle.
    if fill_color || line_color
      self.rect(x, y, width, height, fill_color: fill_color, line_color: line_color, line_width: line_width)
    end

    # Set font.
    self.font(font_family, style: font_style)
    self.font_size(font_size)
    self.fill_color(font_color)

    # Draw text box.
    self.text_box(text.to_s,
                  at: [(x + h_pad).in, (y - v_pad).in],
                  width: (width - 2 * h_pad).in,
                  height: (height - 2 * v_pad).in,
                  align: h_align,
                  valign: v_align,
                  inline_format: true,
                  overflow: :shrink_to_fit)

  end

  # Draws grid.
  def grid(x, y, column_widths, rows, row_height, options = {})

    # Save current properties.
    self.save_current_properties()

    # Load passed options or fall back to defaults.
    fill_color = options.fetch(:fill_color, nil)
    if options.key?(:line_color)
      line_color = options.fetch(:line_color)
      hline_color = line_color
      vline_color = line_color
    else
      hline_color = options.fetch(:hline_color, self.class::DEFAULT_LINE_COLOR)
      vline_color = options.fetch(:vline_color, self.class::DEFAULT_LINE_COLOR)
    end
    line_width = options.fetch(:line_width, nil)
    header_row = options.fetch(:header_row, false)
    if header_row
      first_row_height = 2 * row_height
      first_row_color = self.class::DEFAULT_HEADER_FILL_COLOR
    else
      first_row_height = options.fetch(:first_row_height, row_height)
      first_row_color = options.fetch(:first_row_color, nil)
    end
    first_column_color = options.fetch(:first_column_color, nil)
    row_colors = options.fetch(:row_colors, nil)
    headers = options.fetch(:headers, nil)
    headers_h_align = options.fetch(:headers_h_align, nil)
    header_font_family = options.fetch(:font, self.class::DEFAULT_FONT_FAMILY)
    header_font_style = options.fetch(:style, :bold)
    header_font_size = options.fetch(:size, self.class::DEFAULT_FONT_SIZE)
    header_font_color = options.fetch(:color, self.class::DEFAULT_FONT_COLOR)
    font_family = options.fetch(:font, self.class::DEFAULT_FONT_FAMILY)
    font_style = options.fetch(:style, self.class::DEFAULT_FONT_STYLE)
    font_size = options.fetch(:size, self.class::DEFAULT_FONT_SIZE)
    font_color = options.fetch(:color, self.class::DEFAULT_FONT_COLOR)
    data = options.fetch(:data, nil)
    data_h_align = options.fetch(:data_h_align, nil)
    data_format_codes = options.fetch(:data_format_codes, nil)
    data_only = options.fetch(:data_only, false)

    # Calculate total area height.
    total_height = rows * row_height + (first_row_height - row_height)

    # Skip drawing table if data only option passed.
    unless data_only

      # Shade first row and column if options passed.
      unless first_column_color.blank?
        self.rect(x, y, column_widths[0], total_height, fill_color: first_column_color, line_color: nil)
      end
      unless first_row_color.blank?
        self.rect(x, y, column_widths.sum, first_row_height, fill_color: first_row_color, line_color: nil)
      end

      # Shade rows if necessary.
      unless row_colors.blank?
        row_y = y - first_row_height
        (0...rows - 1).each do |r|
          row_color_index = r % row_colors.length
          row_color = row_colors[row_color_index]
          self.rect(x, row_y, column_widths.sum, row_height, fill_color: row_color, line_color: nil)
          row_y -= row_height
        end
      end

      # Draw column dividers.
      self.vline(x, y, total_height, line_color: vline_color, line_width: line_width)
      column_x = x
      column_widths.each do |w|
        column_x += w
        self.vline(column_x, y, total_height, line_color: vline_color, line_width: line_width)
      end

      # Draw row dividers.
      self.hline(x, y, column_widths.sum, line_color: hline_color, line_width: line_width)
      row_y = y - first_row_height
      (0...rows).each do |r|
        self.hline(x, row_y, column_widths.sum, line_color: hline_color, line_width: line_width)
        row_y -= row_height
      end

      # Draw headers if necessary.
      unless headers.blank?
        column_x = x
        headers.each_with_index do |h, i|
          h_align = headers_h_align.blank? ? :center : headers_h_align[i]
          self.txtb(h, column_x + 0.05, y, column_widths[i] - 0.1, first_row_height, font: header_font_family, style: header_font_style, size: header_font_size, color: header_font_color, h_align: h_align)
          column_x += column_widths[i]
        end
      end

    end

    # Draw data if necessary.
    unless data.blank?
      row_y = y - (header_row ? first_row_height : 0)
      data.each do |d|
        column_x = x
        d.each_with_index do |v, i|
          h_align = data_h_align.blank? ? :center : data_h_align[i]
          formatted = data_format_codes.blank? ? v.to_s : sprintf(data_format_codes[i], v)
          self.txtb(formatted, column_x + 0.05, row_y, column_widths[i] - 0.1, row_height, font: font_family, style: font_style, size: font_size, color: font_color, h_align: h_align)
          column_x += column_widths[i]
        end
        row_y -= row_height
      end
    end

    # Restore saved properties.
    self.restore_saved_properties()

  end
  alias_method :table, :grid

  # Draws Varland logo.
  def logo(x, y, width, height, options = {})

    # Load passed options or fall back to defaults.
    h_align = options.fetch(:h_align, :center)
    v_align = options.fetch(:v_align, :center)
    variant = options.fetch(:variant, :stacked)
    fill_color = options.fetch(:fill_color, nil)
    invert_colors = options.fetch(:invert_colors, false)
    mono = options.fetch(:mono, false)

    # Draw background.
    self.rect(x, y, width, height, fill_color: fill_color, line_color: nil)

    # Define logo properties.
    case variant
    when :horizontal
      image_width = 3340
      image_height = 1000
    when :horizontal_tagline
      image_width = 3340
      image_height = 1000
    when :vertical
      image_width = 2400
      image_height = 1466
    when :vertical_tagline
      image_width = 2400
      image_height = 1688
    when :mark
      image_width = 1300
      image_height = 1500
    when :stacked
      image_width = 2361
      image_height = 1001
    else
      self.txtb("Logo Error: #{variant.to_s}", x, y, width, height, fill_color: 'ff0000', color: 'ffffff', style: :bold)
      return
    end

    # Store logo path.
    name = "logo_#{variant.to_s}"
    name << "_inverse" if invert_colors
    name << "_mono" if mono
    path = Rails.root.join('lib', 'assets', 'logos', "#{name}.png")
    puts path

    # Calculate ratio.
    logo_ratio = image_height.to_f / image_width.to_f

    # Calculate actual height and width.
    logo_width = width
    logo_height = logo_ratio * logo_width
    if logo_height > height
      logo_height = height
      logo_width = logo_height / logo_ratio
    end

    # Calculate position.
    x_buffer = width - logo_width
    y_buffer = height - logo_height
    case h_align
    when :left
      x_buffer_multiplier = 0
    when :center
      x_buffer_multiplier = 0.5
    when :right
      x_buffer_multiplier = 1
    end
    case v_align
    when :top
      y_buffer_multiplier = 0
    when :center
      y_buffer_multiplier = 0.5
    when :bottom
      y_buffer_multiplier = 1
    end
    logo_x = x + x_buffer_multiplier * x_buffer
    logo_y = y - y_buffer_multiplier * y_buffer

    # Draw logo.
    self.image(path, at: [logo_x.in, logo_y.in], width: logo_width.in, height: logo_height.in)

  end

  # Draws signature.
  def signature(person, x, y, width, height, options = {})

    # Load passed options or fall back to defaults.
    h_align = options.fetch(:h_align, :center)
    v_align = options.fetch(:v_align, :center)
    baseline_shift = options.fetch(:baseline_shift, 0)

    # Determine if graphic file exists. Return error if not.
    path = Rails.root.join('lib', 'assets', 'signatures', "#{person.to_s}.png")
    unless File.file?(path)
      self.txtb("Signature Error: #{person.to_s}", x, y, width, height, fill_color: 'ff0000', color: 'ffffff', style: :bold)
      return
    end

    # Read image dimensions.
    image_width, image_height = FastImage.size(path)

    # Calculate ratio.
    signature_ratio = image_height.to_f / image_width.to_f

    # Calculate actual height and width.
    signature_width = width
    signature_height = signature_ratio * signature_width
    if signature_height > height
      signature_height = height
      signature_width = signature_height / signature_ratio
    end

    # Calculate position.
    x_buffer = width - signature_width
    y_buffer = height - signature_height
    case h_align
    when :left
      x_buffer_multiplier = 0
    when :center
      x_buffer_multiplier = 0.5
    when :right
      x_buffer_multiplier = 1
    end
    case v_align
    when :top
      y_buffer_multiplier = 0
    when :center
      y_buffer_multiplier = 0.5
    when :bottom
      y_buffer_multiplier = 1
    end
    signature_x = x + x_buffer_multiplier * x_buffer
    signature_y = y - y_buffer_multiplier * y_buffer + baseline_shift

    # Draw signature.
    self.image(path, at: [signature_x.in, signature_y.in], width: signature_width.in, height: signature_height.in)

  end

  # Protected methods.
  protected

    # Reference Rails helpers.
    def helpers
      ApplicationController.helpers
    end

end