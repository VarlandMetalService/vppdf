class PayrollReport < VarlandPdf

  PAGE_ORIENTATION = :landscape

  LINE_HEIGHT = 0.2
  HEADER_HEIGHT = 0.25

  ACCOUNT_SUMMARY_COLUMN_WIDTHS = [1, 3.75, 3.75, 1, 1].freeze
  EMPLOYEE_SUMMARY_COLUMN_WIDTHS = [0.75, 3, 3.75, 1, 1, 1].freeze
  GL_COLUMN_WIDTHS = [4, 1.25, 4, 1.25].freeze
  PAYABLES_COLUMN_WIDTHS = [0.75, 2.25, 0.5, 3.8, 1, 1, 1.2].freeze

  TABLE_ROLLOVER_Y = 7.5.freeze
  TABLE_BOTTOM = 0.75.freeze

  TOTAL_CELL_WIDTH = (10.5 / 8.0).freeze

  def initialize()

    super()

    @data = self.load_data
    self.draw_totals(7.5)
    self.draw_payroll_journal(6.5)
    self.start_new_page
    self.draw_disbursement_journal(7.5)
    self.draw_payables(7.25 - 3 * HEADER_HEIGHT - LINE_HEIGHT)
    self.start_new_page
    self.draw_employees(7.5)
    self.start_new_page
    self.draw_accounts(7.5)
    self.draw_header

    string = "<b>PAGE <page> OF <total></b>"
    options = {at: [0.25.in, 0.5.in],
               width: 10.5.in,
               height: 0.25.in,
               align: :center,
               size: 7,
               start_count_at: 1,
               valign: :center,
               inline_format: true}
    self.number_pages(string, options)

  end

  def draw_header
    self.repeat(:all) do
      self.logo(0.25, 8.25, 1, 0.5, variant: :mark, h_align: :left)
      self.txtb("<b>PAYROLL IMPORT REPORT</b>\n<font size='10'>PERIOD ENDING #{Time.iso8601(@data[:period_end]).strftime("%^B %-d, %Y").upcase}</font>", 0.85, 8.25, 8, 0.5, h_align: :left, size: 14)
    end
  end

  def draw_totals(y)
    self.rect(0.25, y, 5 * TOTAL_CELL_WIDTH, HEADER_HEIGHT, fill_color: "aaaaaa", line_color: nil)
    self.rect(0.25 + 5 * TOTAL_CELL_WIDTH, y, 3 * TOTAL_CELL_WIDTH, HEADER_HEIGHT, fill_color: "cccccc", line_color: nil)
    [y, y - HEADER_HEIGHT, y - 3 * HEADER_HEIGHT].each do |line_y|
      self.hline(0.25, line_y, 10.5)
    end
    [0.25, 1.5625, 2.875, 4.1875, 5.5, 6.8125, 8.125, 9.4375, 10.75].each do |x|
      self.vline(x, y, 0.75)
    end
    header_options = {
      size: 8,
      style: :bold
    }
    data_options = {
      h_pad: 0.1,
      size: 14,
      style: :bold
    }
    net = @data[:totals][:earnings] - @data[:totals][:deductions] - @data[:totals][:employee_taxes]
    self.txtb("GROSS PAY", 0.25, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(@data[:totals][:earnings], 0.25, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
    self.txtb("DEDUCTIONS", 0.25 + TOTAL_CELL_WIDTH, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(@data[:totals][:deductions], 0.25 + TOTAL_CELL_WIDTH, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
    self.txtb("EMPLOYEE TAXES", 0.25 + 2 * TOTAL_CELL_WIDTH, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(@data[:totals][:employee_taxes], 0.25 + 2 * TOTAL_CELL_WIDTH, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
    self.txtb("NET PAY", 0.25 + 3 * TOTAL_CELL_WIDTH, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(net, 0.25 + 3 * TOTAL_CELL_WIDTH, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
    self.txtb("EMPLOYER TAXES", 0.25 + 4 * TOTAL_CELL_WIDTH, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(@data[:totals][:employer_taxes], 0.25 + 4 * TOTAL_CELL_WIDTH, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
    self.txtb("NET PAY ACH", 0.25 + 5 * TOTAL_CELL_WIDTH, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(@data[:accumulations][:net], 0.25 + 5 * TOTAL_CELL_WIDTH, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
    self.txtb("TAXES ACH", 0.25 + 6 * TOTAL_CELL_WIDTH, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(@data[:accumulations][:tax], 0.25 + 6 * TOTAL_CELL_WIDTH, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
    self.txtb("TRUST ACH", 0.25 + 7 * TOTAL_CELL_WIDTH, y, TOTAL_CELL_WIDTH, 0.25, header_options)
    self.acctb(@data[:accumulations][:trust], 0.25 + 7 * TOTAL_CELL_WIDTH, y - HEADER_HEIGHT, TOTAL_CELL_WIDTH, 2 * HEADER_HEIGHT, data_options)
  end

  def draw_payables(y)
    self.draw_payables_title(y)
    top_y = y
    y -= 2 * HEADER_HEIGHT
    alt = false
    @data[:payables].each do |record|
      alt = !alt
      height_required = record[:line_items].length * LINE_HEIGHT
      height_required += 0.6 * LINE_HEIGHT if record[:line_items].length == 1 && record[:vendor][:name_2].present?
      bottom = y - height_required
      if bottom < TABLE_BOTTOM
        [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y].each do |y|
          self.hline(0.25, y, PAYABLES_COLUMN_WIDTHS.sum)
        end
        [0.25, 0.25 + PAYABLES_COLUMN_WIDTHS.sum].each do |x|
          self.vline(x, top_y, top_y - y)
        end
        [0, 1, 2, 4, 5].each do |i|
          self.vline(PAYABLES_COLUMN_WIDTHS[0..i].sum + 0.25,
                     top_y - HEADER_HEIGHT,
                     top_y - y - HEADER_HEIGHT)
        end
        self.txtb("(continued)", 0.25, y, PAYABLES_COLUMN_WIDTHS.sum, LINE_HEIGHT, size: 7, style: :italic)
        self.start_new_page
        self.draw_payables_title(TABLE_ROLLOVER_Y, true)
        top_y = TABLE_ROLLOVER_Y
        y = TABLE_ROLLOVER_Y - 2 * HEADER_HEIGHT
        alt = true
      end
      self.draw_payable(y, record, alt)
      y -= height_required
    end
    [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y].each do |y|
      self.hline(0.25, y, PAYABLES_COLUMN_WIDTHS.sum)
    end
    [0.25, 0.25 + PAYABLES_COLUMN_WIDTHS.sum].each do |x|
      self.vline(x, top_y, top_y - y)
    end
    [0, 1, 2, 4, 5].each do |i|
      self.vline(PAYABLES_COLUMN_WIDTHS[0..i].sum + 0.25,
                 top_y - HEADER_HEIGHT,
                 top_y - y - HEADER_HEIGHT)
    end
  end

  def draw_employees(y)
    self.draw_employees_title(y)
    top_y = y
    y -= 2 * HEADER_HEIGHT
    alt = false
    @data[:labor].each do |record|
      alt = !alt
      height_required = record[:accounts].length * LINE_HEIGHT
      bottom = y - height_required
      if bottom < TABLE_BOTTOM
        [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y].each do |y|
          self.hline(0.25, y, EMPLOYEE_SUMMARY_COLUMN_WIDTHS.sum)
        end
        [0.25, 0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS.sum].each do |x|
          self.vline(x, top_y, top_y - y)
        end
        [0, 1, 4].each do |i|
          self.vline(EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..i].sum + 0.25,
                     top_y - HEADER_HEIGHT,
                     top_y - y - HEADER_HEIGHT)
        end
        self.txtb("(continued)", 0.25, y, EMPLOYEE_SUMMARY_COLUMN_WIDTHS.sum, LINE_HEIGHT, size: 7, style: :italic)
        self.start_new_page
        self.draw_employees_title(TABLE_ROLLOVER_Y, true)
        top_y = TABLE_ROLLOVER_Y
        y = TABLE_ROLLOVER_Y - 2 * HEADER_HEIGHT
        alt = true
      end
      self.draw_employee(y, record, alt)
      y -= height_required
    end
    [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y].each do |y|
      self.hline(0.25, y, EMPLOYEE_SUMMARY_COLUMN_WIDTHS.sum)
    end
    [0.25, 0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS.sum].each do |x|
      self.vline(x, top_y, top_y - y)
    end
    [0, 1, 4].each do |i|
      self.vline(EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..i].sum + 0.25,
                 top_y - HEADER_HEIGHT,
                 top_y - y - HEADER_HEIGHT)
    end
  end

  def load_data
    local_file = Rails.root.join('lib', 'payroll', 'export.json')
    ftp = Net::FTP.new('ibmi.varland.com')
    ftp.login("qsecofr", "secret")
    ftp.gettextfile("/payroll/export.json", local_file)
    ftp.close
    file_data = File.read(local_file)
    return JSON.parse(file_data, symbolize_names: true)
  end

  def draw_accounts(y)
    self.draw_accounts_title(y)
    top_y = y
    y -= 2 * HEADER_HEIGHT
    alt = false
    @data[:accounts].each do |record|
      alt = !alt
      height_required = record[:employees].length * LINE_HEIGHT
      bottom = y - height_required
      if bottom < TABLE_BOTTOM
        [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y].each do |y|
          self.hline(0.25, y, ACCOUNT_SUMMARY_COLUMN_WIDTHS.sum)
        end
        [0.25, 0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS.sum].each do |x|
          self.vline(x, top_y, top_y - y)
        end
        [0, 1, 3].each do |i|
          self.vline(ACCOUNT_SUMMARY_COLUMN_WIDTHS[0..i].sum + 0.25,
                     top_y - HEADER_HEIGHT,
                     top_y - y - HEADER_HEIGHT)
        end
        self.txtb("(continued)", 0.25, y, ACCOUNT_SUMMARY_COLUMN_WIDTHS.sum, LINE_HEIGHT, size: 7, style: :italic)
        self.start_new_page
        self.draw_accounts_title(TABLE_ROLLOVER_Y, true)
        top_y = TABLE_ROLLOVER_Y
        y = TABLE_ROLLOVER_Y - 2 * HEADER_HEIGHT
        alt = true
      end
      self.draw_account(y, record, alt)
      y -= height_required
    end
    [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y].each do |y|
      self.hline(0.25, y, ACCOUNT_SUMMARY_COLUMN_WIDTHS.sum)
    end
    [0.25, 0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS.sum].each do |x|
      self.vline(x, top_y, top_y - y)
    end
    [0, 1, 3].each do |i|
      self.vline(ACCOUNT_SUMMARY_COLUMN_WIDTHS[0..i].sum + 0.25,
                 top_y - HEADER_HEIGHT,
                 top_y - y - HEADER_HEIGHT)
    end
  end

  def draw_accounts_title(y, continued = false)
    self.txtb("ACCOUNT WORKING HOURS SUMMARY #{continued ? "<i>(continued)</i>" : ""}",
              0.25,
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS.sum,
              HEADER_HEIGHT,
              size: 9,
              style: :bold,
              h_align: :left,
              h_pad: 0.1,
              fill_color: "aaaaaa")
    y -= HEADER_HEIGHT
    header_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1,
      fill_color: "cccccc"
    }
    self.txtb("ACCOUNT",
              0.25,
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS[0],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
    self.txtb("NAME",
              0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS[0],
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS[1],
              HEADER_HEIGHT,
              header_options)
    self.txtb("EMPLOYEE BREAKDOWN",
              0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS[0..1].sum,
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS[2..3].sum,
              HEADER_HEIGHT,
              header_options)
    self.txtb("TOTAL",
              0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS[0..3].sum,
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS[4],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
  end

  def draw_account(y, account, alt)

    height_required = account[:employees].length * LINE_HEIGHT

    self.rect(0.25, y, ACCOUNT_SUMMARY_COLUMN_WIDTHS.sum, height_required, fill_color: "eeeeee", line_color: nil) if alt

    data_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1
    }
    self.txtb(account[:account],
              0.25,
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS[0],
              LINE_HEIGHT,
              data_options.merge({ h_align: :center }))
    self.txtb(account[:name],
              0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS[0],
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS[1],
              LINE_HEIGHT,
              data_options)
    self.txtb("#{self.format_number(account[:hours], decimals: 1)} HRS",
              0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS[0..3].sum,
              y,
              ACCOUNT_SUMMARY_COLUMN_WIDTHS[4],
              LINE_HEIGHT,
              data_options.merge({ h_align: :right }))

    account[:employees].each do |record|
      self.txtb("#{record[:number]} #{record[:name]}",
                0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS[0..1].sum,
                y,
                ACCOUNT_SUMMARY_COLUMN_WIDTHS[2],
                LINE_HEIGHT,
                data_options)
      self.txtb("#{self.format_number(record[:hours], decimals: 1)} HRS",
                0.25 + ACCOUNT_SUMMARY_COLUMN_WIDTHS[0..2].sum,
                y,
                ACCOUNT_SUMMARY_COLUMN_WIDTHS[3],
                LINE_HEIGHT,
                data_options.merge({ h_align: :right }))
      y -= LINE_HEIGHT
    end

  end

  def draw_employees_title(y, continued = false)
    self.txtb("EMPLOYEE WORKING HOURS SUMMARY #{continued ? "<i>(continued)</i>" : ""}",
              0.25,
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS.sum,
              HEADER_HEIGHT,
              size: 9,
              style: :bold,
              h_align: :left,
              h_pad: 0.1,
              fill_color: "aaaaaa")
    y -= HEADER_HEIGHT
    header_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1,
      fill_color: "cccccc"
    }
    self.txtb("#",
              0.25,
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
    self.txtb("NAME",
              0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0],
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS[1],
              HEADER_HEIGHT,
              header_options)
    self.txtb("HOURS BREAKDOWN",
              0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..1].sum,
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS[2..4].sum,
              HEADER_HEIGHT,
              header_options)
    self.txtb("TOTAL",
              0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..4].sum,
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS[5],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
  end

  def draw_employee(y, employee, alt)

    height_required = employee[:accounts].length * LINE_HEIGHT

    self.rect(0.25, y, EMPLOYEE_SUMMARY_COLUMN_WIDTHS.sum, height_required, fill_color: "eeeeee", line_color: nil) if alt

    data_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1
    }
    self.txtb(employee[:number],
              0.25,
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0],
              LINE_HEIGHT,
              data_options.merge({ h_align: :center }))
    self.txtb(employee[:name],
              0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0],
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS[1],
              LINE_HEIGHT,
              data_options)
    hours_color = case
                  when employee[:total_hours].to_f < 40.0 then "ff0000"
                  when employee[:total_hours].to_f == 40.0 then "000000"
                  when employee[:total_hours].to_f > 40.0 then "0000ff"
                  end
    self.txtb("#{self.format_number(employee[:total_hours], decimals: 1)} HRS",
              0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..4].sum,
              y,
              EMPLOYEE_SUMMARY_COLUMN_WIDTHS[5],
              LINE_HEIGHT,
              data_options.merge({ h_align: :right, color: hours_color }))

    employee[:accounts].each do |record|
      self.txtb("#{record[:account]} - #{record[:name]}",
                0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..1].sum,
                y,
                EMPLOYEE_SUMMARY_COLUMN_WIDTHS[2],
                LINE_HEIGHT,
                data_options)
      self.txtb("#{self.format_number(record[:hours], decimals: 1)} HRS",
                0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..2].sum,
                y,
                EMPLOYEE_SUMMARY_COLUMN_WIDTHS[3],
                LINE_HEIGHT,
                data_options.merge({ h_align: :right }))
      self.txtb("#{self.format_number(100.0 * record[:percent], decimals: 2)}%",
                0.25 + EMPLOYEE_SUMMARY_COLUMN_WIDTHS[0..3].sum,
                y,
                EMPLOYEE_SUMMARY_COLUMN_WIDTHS[4],
                LINE_HEIGHT,
                data_options.merge({ h_align: :right }))
      y -= LINE_HEIGHT
    end

  end

  def draw_payables_title(y, continued = false)
    self.txtb("PAYABLES #{continued ? "<i>(continued)</i>" : ""}",
              0.25,
              y,
              PAYABLES_COLUMN_WIDTHS.sum,
              HEADER_HEIGHT,
              size: 9,
              style: :bold,
              h_align: :left,
              h_pad: 0.1,
              fill_color: "aaaaaa")
    y -= HEADER_HEIGHT
    header_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1,
      fill_color: "cccccc"
    }
    self.txtb("VENDOR",
              0.25,
              y,
              PAYABLES_COLUMN_WIDTHS[0],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
    self.txtb("VENDOR NAME",
              0.25 + PAYABLES_COLUMN_WIDTHS[0],
              y,
              PAYABLES_COLUMN_WIDTHS[1],
              HEADER_HEIGHT,
              header_options)
    self.txtb("ACH",
              0.25 + PAYABLES_COLUMN_WIDTHS[0..1].sum,
              y,
              PAYABLES_COLUMN_WIDTHS[2],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
    self.txtb("DISBURSEMENT BREAKDOWN",
              0.25 + PAYABLES_COLUMN_WIDTHS[0..2].sum,
              y,
              PAYABLES_COLUMN_WIDTHS[3..4].sum,
              HEADER_HEIGHT,
              header_options)
    self.txtb("TOTAL",
              0.25 + PAYABLES_COLUMN_WIDTHS[0..4].sum,
              y,
              PAYABLES_COLUMN_WIDTHS[5],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
    self.txtb("DUE DATE",
              0.25 + PAYABLES_COLUMN_WIDTHS[0..5].sum,
              y,
              PAYABLES_COLUMN_WIDTHS[6],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
  end

  def draw_payable(y, payable, alt)

    height_required = payable[:line_items].length * LINE_HEIGHT
    height_required += 0.6 * LINE_HEIGHT if payable[:line_items].length == 1 && payable[:vendor][:name_2].present?

    self.rect(0.25, y, PAYABLES_COLUMN_WIDTHS.sum, height_required, fill_color: "eeeeee", line_color: nil) if alt

    data_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1
    }
    self.txtb(payable[:vendor_id],
              0.25,
              y,
              PAYABLES_COLUMN_WIDTHS[0],
              LINE_HEIGHT,
              data_options.merge({ h_align: :center }))
    vendor_name = [payable[:vendor][:name]]
    vendor_name << payable[:vendor][:name_2] if payable[:vendor][:name_2].present?
    self.txtb(payable[:vendor][:name],
              0.25 + PAYABLES_COLUMN_WIDTHS[0],
              y,
              PAYABLES_COLUMN_WIDTHS[1],
              LINE_HEIGHT,
              data_options)
    if payable[:vendor][:name_2].present?
      self.txtb(payable[:vendor][:name_2],
                0.25 + PAYABLES_COLUMN_WIDTHS[0],
                y - 0.6 * LINE_HEIGHT,
                PAYABLES_COLUMN_WIDTHS[1],
                LINE_HEIGHT,
                data_options)
    end
    self.txtb(payable[:vendor][:achPayments] ? "YES" : "NO",
              0.25 + PAYABLES_COLUMN_WIDTHS[0..1].sum,
              y,
              PAYABLES_COLUMN_WIDTHS[2],
              LINE_HEIGHT,
              data_options.merge({ h_align: :center }))
    self.acctb(payable[:total],
               0.25 + PAYABLES_COLUMN_WIDTHS[0..4].sum,
               y,
               PAYABLES_COLUMN_WIDTHS[5],
               LINE_HEIGHT,
               data_options)
    self.txtb(Time.iso8601(payable[:due_date]).strftime("%m/%d/%y"),
              0.25 + PAYABLES_COLUMN_WIDTHS[0..5].sum,
              y,
              PAYABLES_COLUMN_WIDTHS[6],
              LINE_HEIGHT,
              data_options.merge({ h_align: :center }))
    payable[:line_items].each do |record|
      self.txtb("#{record[:account]} - #{record[:description]}",
                0.25 + PAYABLES_COLUMN_WIDTHS[0..2].sum,
                y,
                PAYABLES_COLUMN_WIDTHS[3],
                LINE_HEIGHT,
                data_options)
      self.acctb(record[:amount],
                 0.25 + PAYABLES_COLUMN_WIDTHS[0..3].sum,
                 y,
                 PAYABLES_COLUMN_WIDTHS[4],
                 LINE_HEIGHT,
                 data_options)
      y -= LINE_HEIGHT
    end

  end

  def draw_gl_title(y, name, continued = false)
    self.txtb("#{name.upcase} #{continued ? "<i>(continued)</i>" : ""}",
              0.25,
              y,
              GL_COLUMN_WIDTHS.sum,
              HEADER_HEIGHT,
              size: 9,
              style: :bold,
              h_align: :left,
              h_pad: 0.1,
              fill_color: "aaaaaa")
    y -= HEADER_HEIGHT
    header_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1,
      fill_color: "cccccc"
    }
    self.txtb("ACCOUNT",
              0.25,
              y,
              GL_COLUMN_WIDTHS[0],
              HEADER_HEIGHT,
              header_options)
    self.txtb("AMOUNT",
              0.25 + GL_COLUMN_WIDTHS[0],
              y,
              GL_COLUMN_WIDTHS[1],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
    self.txtb("ACCOUNT",
              0.25 + GL_COLUMN_WIDTHS[0..1].sum,
              y,
              GL_COLUMN_WIDTHS[2],
              HEADER_HEIGHT,
              header_options)
    self.txtb("AMOUNT",
              0.25 + GL_COLUMN_WIDTHS[0..2].sum,
              y,
              GL_COLUMN_WIDTHS[3],
              HEADER_HEIGHT,
              header_options.merge(h_align: :center))
  end

  def draw_payroll_journal(y)
    self.draw_gl_entry(y, "PAYROLL JOURNAL", @data[:payroll_journal])
  end

  def draw_disbursement_journal(y)
    self.draw_gl_entry(y, "DISBURSEMENT JOURNAL", @data[:disbursement_journal])
  end

  def draw_gl_entry(y, title, entry)
    self.draw_gl_title(y, title)
    top_y = y
    y -= 2 * HEADER_HEIGHT
    alt = false
    max_index = [entry[:debits].length, entry[:credits].length].max - 1
    (0..max_index).each do |i|
      alt = !alt
      height_required = LINE_HEIGHT
      bottom = y - height_required
      if bottom < TABLE_BOTTOM
        [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y].each do |y|
          self.hline(0.25, y, GL_COLUMN_WIDTHS.sum)
        end
        [0.25, 0.25 + GL_COLUMN_WIDTHS.sum, 0.25 + 0.5 * GL_COLUMN_WIDTHS.sum].each do |x|
          self.vline(x, top_y, top_y - y)
        end
        self.txtb("(continued)", 0.25, y, GL_COLUMN_WIDTHS.sum, LINE_HEIGHT, size: 7, style: :italic)
        self.start_new_page
        self.draw_gl_title(TABLE_ROLLOVER_Y, title, true)
        top_y = TABLE_ROLLOVER_Y
        y = TABLE_ROLLOVER_Y - 2 * HEADER_HEIGHT
        alt = true
      end
      debit = entry[:debits][i]
      credit = entry[:credits][i]
      self.draw_transaction(y, debit, credit, alt)
      y -= height_required
    end
    self.draw_total_transaction(y, entry[:total_debits], entry[:total_credits])
    y -= HEADER_HEIGHT
    [top_y, top_y - HEADER_HEIGHT, top_y - 2 * HEADER_HEIGHT, y, y + HEADER_HEIGHT].each do |y|
      self.hline(0.25, y, GL_COLUMN_WIDTHS.sum)
    end
    [0.25, 0.25 + GL_COLUMN_WIDTHS.sum, 0.25 + 0.5 * GL_COLUMN_WIDTHS.sum].each do |x|
      self.vline(x, top_y, top_y - y)
    end
  end

  def draw_transaction(y, debit, credit, alt)

    self.rect(0.25, y, GL_COLUMN_WIDTHS.sum, LINE_HEIGHT, fill_color: "eeeeee", line_color: nil) if alt

    data_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1
    }
    self.txtb("#{debit[:account]} - #{debit[:description]}",
              0.25,
              y,
              GL_COLUMN_WIDTHS[0],
              LINE_HEIGHT,
              data_options) unless debit.blank?
    self.acctb(debit[:amount],
               0.25 + GL_COLUMN_WIDTHS[0],
               y,
               GL_COLUMN_WIDTHS[1],
               LINE_HEIGHT,
               data_options) unless debit.blank?
    self.txtb("#{credit[:account]} - #{credit[:description]}",
              0.25 + GL_COLUMN_WIDTHS[0..1].sum,
              y,
              GL_COLUMN_WIDTHS[2],
              LINE_HEIGHT,
              data_options) unless credit.blank?
    self.acctb(credit[:amount],
               0.25 + GL_COLUMN_WIDTHS[0..2].sum,
               y,
               GL_COLUMN_WIDTHS[3],
               LINE_HEIGHT,
               data_options) unless credit.blank?

  end

  def draw_total_transaction(y, debit, credit)

    self.rect(0.25, y, GL_COLUMN_WIDTHS.sum, HEADER_HEIGHT, fill_color: "cccccc", line_color: nil)

    data_options = {
      size: 8,
      style: :bold,
      h_align: :left,
      h_pad: 0.1
    }
    self.txtb("TOTAL DEBITS",
              0.25,
              y,
              GL_COLUMN_WIDTHS[0],
              HEADER_HEIGHT,
              data_options)
    self.acctb(debit,
               0.25 + GL_COLUMN_WIDTHS[0],
               y,
               GL_COLUMN_WIDTHS[1],
               HEADER_HEIGHT,
               data_options.merge({ debug: :false }))
    self.txtb("TOTAL CREDITS",
              0.25 + GL_COLUMN_WIDTHS[0..1].sum,
              y,
              GL_COLUMN_WIDTHS[2],
              HEADER_HEIGHT,
              data_options)
    self.acctb(credit,
               0.25 + GL_COLUMN_WIDTHS[0..2].sum,
               y,
               GL_COLUMN_WIDTHS[3],
               HEADER_HEIGHT,
               data_options)

  end

end