class DataTable

  # Attribute accessors for table properties.
  attr_accessor :x,
                :y,
                :width,
                :height,
                :cell_h_buffer,
                :cell_v_buffer,
                :column_widths

  # Attribute accessors for header properties.
  attr_accessor :has_header,
                :header_height,
                :header_bg_color,
                :header_vline_color,
                :header_hline_color,
                :header_line_width,
                :header_font_size,
                :header_font_style,
                :header_font_color,
                :header_font,
                :headers,
                :headers_h_align,
                :headers_v_align

  # Attribute accessors for data properties.
  attr_accessor :rows,
                :data_vline_color,
                :data_hline_color,
                :data_line_width,
                :data_font_size,
                :data_font_style,
                :data_font_color,
                :data_font,
                :row_height,
                :rows_h_align,
                :rows_v_align,
                :rows_format,
                :row_bg_colors

  # Constructor. Initializes object.
  def initialize(options = {})

    # Initialize table properties.
    @x = options.fetch(:x, 0)
    @y = options.fetch(:y, 0)
    @width = options.fetch(:width, 0)
    @height = options.fetch(:height, 0)
    @cell_h_buffer = options.fetch(:cell_h_buffer, 0.1)
    @cell_v_buffer = options.fetch(:cell_v_buffer, 0.05)
    @column_widths = options.fetch(:column_widths, [])

    # Initialize header properties.
    @has_header = options.fetch(:has_header, true)
    @header_height = options.fetch(:header_height, 0.5)
    @header_bg_color = options.fetch(:header_bg_color, 'cccccc')
    @header_vline_color = options.fetch(:header_vline_color, '000000')
    @header_hline_color = options.fetch(:header_hline_color, '000000')
    @header_line_width = options.fetch(:header_line_width, 0.01)
    @header_font_size = options.fetch(:header_font_size, 10)
    @header_font_style = options.fetch(:header_font_style, :bold)
    @header_font_color = options.fetch(:header_font_color, '000000')
    @header_font = options.fetch(:header_font, 'Helvetica')
    @headers = options.fetch(:headers, [])
    @headers_h_align = options.fetch(:headers_h_align, nil)
    @headers_v_align = options.fetch(:headers_v_align, nil)

    # Initialize data properties.
    @row_height = options.fetch(:row_height, 0.25)
    @data_vline_color = options.fetch(:data_vline_color, '000000')
    @data_hline_color = options.fetch(:data_hline_color, '000000')
    @data_line_width = options.fetch(:data_line_width, 0.01)
    @data_font_size = options.fetch(:data_font_size, 10)
    @data_font_style = options.fetch(:data_font_style, :normal)
    @data_font_color = options.fetch(:data_font_color, '000000')
    @data_font = options.fetch(:data_font, 'Helvetica')
    @rows = options.fetch(:rows, [])
    @rows_h_align = options.fetch(:rows_h_align, nil)
    @rows_v_align = options.fetch(:rows_v_align, nil)
    @rows_format = options.fetch(:rows_format, nil)
    @row_bg_colors = options.fetch(:row_bg_colors, nil)

  end

  # Draws table on PDF.
  def draw(pdf)

    # Determine number of pages needed.
    pages = self.calculate_pages
    return if pages == 0

    # Determine number of rows per page.
    rows_per_page = self.rows_per_page

    # Process each row.
    row_y = 0
    row_index = 0
    @rows.each_with_index do |row, index|

      # If this is the first row on a page, create new page if necessary and draw header.
      if index % rows_per_page == 0
        if index != 0
          pdf.start_new_page
        end
        #pdf.rect(@x, @y, @width, @height, fill_color: 'edf3fe', line_color: nil)
        self.draw_header(pdf)
        row_y = @y - (@has_header ? @header_height : 0)
        row_index = 0
      end

      # Draw row.
      self.draw_row(pdf, row, row_y, row_index)
      
      # Adjust y position for next row.
      row_y -= @row_height
      row_index += 1

    end

  end

  # Shortcut method for setting line widths. May either pass single
  # value to set all widths or two dimensional array to set header
  # and data widths separately.
  def line_width=(val)
    case val
    when Float, NilClass
      @header_line_width = val
      @data_line_width = val
    when Array
      @header_line_width = val[0]
      @data_line_width = val[1]
    else
      return
    end
  end

  # Shortcut method for setting line colors. May either pass single
  # value to set all colors or two dimensional array to set horizontal
  # and vertical colors separately.
  def line_color=(val)
    case val
    when String, NilClass
      @header_vline_color = val
      @header_hline_color = val
      @data_vline_color = val
      @data_hline_color = val
    when Array
      @header_hline_color = val[0]
      @data_hline_color = val[0]
      @header_vline_color = val[1]
      @data_vline_color = val[1]
    else
      puts val.class
      return
    end
  end

  protected

    # Draws single data row.
    def draw_row(pdf, row, y, index)

      # Shade background if necessary.
      unless @row_bg_colors.blank?
        bg_index = index % @row_bg_colors.length
        pdf.rect(@x,
                 y,
                 @column_widths.sum,
                 @row_height,
                 fill_color: @row_bg_colors[bg_index],
                 line_color: nil)
      end
      
      # Draw lines.
      unless @data_line_width.blank? || @data_line_width == 0

        # Draw horizontal lines above & below header.
        unless @data_hline_color.blank?
          pdf.hline(@x,
                    y,
                    @column_widths.sum,
                    line_color: @data_hline_color,
                    line_width: @data_line_width)
          pdf.hline(@x,
                    y - @row_height,
                    @column_widths.sum,
                    line_color: @data_hline_color,
                    line_width: @data_line_width)
        end

        # Draw vertical lines.
        unless @data_vline_color.blank?
          pdf.vline(@x,
                    y,
                    @row_height,
                    line_color: @data_vline_color,
                    line_width: @data_line_width)
          column_x = @x
          @column_widths.each do |w|
            column_x += w
            pdf.vline(column_x,
                      y,
                      @row_height,
                      line_color: @data_vline_color,
                      line_width: @data_line_width)
          end
        end

      end

      # Print each value.
      column_x = @x
      row.each_with_index do |value, index|
        h_align = @rows_h_align.blank? ? :center : @rows_h_align[index]
        v_align = @rows_v_align.blank? ? :center : @rows_v_align[index]
        format_code = @rows_format.blank? ? '%s' : @rows_format[index]
        formatted = sprintf(format_code, value)
        pdf.txtb(formatted,
                 column_x + @cell_h_buffer,
                 y - @cell_v_buffer,
                 @column_widths[index] - 2 * @cell_h_buffer,
                 @row_height - 2 * @cell_v_buffer,
                 font: @data_font,
                 style: @data_font_style,
                 size: @data_font_size,
                 color: @data_font_color,
                 h_align: h_align,
                 v_align: v_align)
        column_x += @column_widths[index]
      end

    end

    # Draws header.
    def draw_header(pdf)

      # Exit if table doesn't have header.
      return unless @has_header

      # Shade table header.
      pdf.rect(@x,
               @y,
               @column_widths.sum,
               @header_height,
               fill_color: @header_bg_color,
               line_color: nil)
      
      # Draw lines.
      unless @header_line_width.blank? || @header_line_width == 0

        # Draw horizontal lines above and below header.
        unless @header_hline_color.blank?
          pdf.hline(@x,
                    @y,
                    @column_widths.sum,
                    line_color: @header_hline_color,
                    line_width: @header_line_width)
          pdf.hline(@x,
                    @y - @header_height,
                    @column_widths.sum,
                    line_color: @header_hline_color,
                    line_width: @header_line_width)
        end

        # Draw vertical lines.
        unless @header_vline_color.blank?
          pdf.vline(@x,
                    @y,
                    @header_height,
                    line_color: @header_vline_color,
                    line_width: @header_line_width)
          column_x = @x
          @column_widths.each do |w|
            column_x += w
            pdf.vline(column_x,
                      @y,
                      @header_height,
                      line_color: @header_vline_color,
                      line_width: @header_line_width)
          end
        end

      end

      # Draw text.
      unless @headers.length == 0

        # Print each header.
        column_x = @x
        @headers.each_with_index do |header, index|
          h_align = @headers_h_align.blank? ? :center : @headers_h_align[index]
          v_align = @headers_v_align.blank? ? :center : @headers_v_align[index]
          pdf.txtb(header,
                   column_x + @cell_h_buffer,
                   @y - @cell_v_buffer,
                   @column_widths[index] - 2 * @cell_h_buffer,
                   @header_height - 2 * @cell_v_buffer,
                   font: @header_font,
                   style: @header_font_style,
                   size: @header_font_size,
                   color: @header_font_color,
                   h_align: h_align,
                   v_align: v_align)
          column_x += @column_widths[index]
        end

      end

    end

    # Calculates rows per page.
    def rows_per_page

      # Calculate height available for rows.
      rows_height = @height - (@has_header ? @header_height : 0)

      # Return number of rows per page.
      return (rows_height.to_f / @row_height.to_f).floor

    end

    # Calculates number of pages required.
    def calculate_pages

      # If no rows, return 0.
      return 0 if @rows.length == 0

      # Return number of pages.
      return (@rows.length.to_f / self.rows_per_page.to_f).ceil

    end

end