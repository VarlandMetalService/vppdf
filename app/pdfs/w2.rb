# Class for printing W2s.
class W2 < VarlandPdf

  # Constructor.
  def initialize

    # Call parent constructor.
    super()

    # Store details.
    @box_height = 0.32
    @filler_height = 4 - (12 * @box_height)

    # Load data.
    self.load_data
    puts @data

    # Draw data for each employee.
    @data[:employees].each_with_index do |employee, index|
      self.start_new_page unless index == 0
      self.draw_box(10.5, "B")
      self.draw_box(5, "C")
      self.draw_employee_data(10.5, employee)
      self.draw_employee_data(5, employee)
      self.start_new_page
      self.draw_instructions(10.5, "B")
      self.draw_instructions(5, "C")
      self.start_new_page
      self.draw_box(10.5, "1")
      self.draw_box(5, "2")
      self.draw_employee_data(10.5, employee)
      self.draw_employee_data(5, employee)
      self.start_new_page
      self.draw_instructions(5, "2")
    end

  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://json400.varland.com/w2")
  end

  def draw_employee_data(y, employee)

    # Draw data.
    y -= 0.08
    data_options = { h_align: :left, v_align: :top, h_pad: 0.05, v_pad: 0.025, size: 9, font: "SF Mono", style: :bold, color: "000000" }
    amount_options = { h_align: :right, v_align: :top, h_pad: 0.05, v_pad: 0.025, size: 9, font: "SF Mono", style: :bold, color: "000000" }
    self.txtb(employee[:_ssn], 2, y, 1.7, @box_height - 0.07, data_options)
    y -= @box_height
    self.txtb("31-0513102", 0.5, y, 3.9, @box_height - 0.07, data_options)
    self.txtb(self.format_number(employee[:federalTaxableWages], decimals: 2), 4.4, y, 1.8, @box_height - 0.07, amount_options)
    self.txtb(self.format_number(employee[:federalTaxWithheld], decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    y -= @box_height
    self.txtb("VARLAND METAL SERVICE, INC.\n3231 FREDONIA AVENUE\nCINCINNATI, OH 45229", 0.5, y, 3.9, 3 * @box_height - 0.07, data_options)
    self.txtb(self.format_number(employee[:socialSecurityWages], decimals: 2), 4.4, y, 1.8, @box_height - 0.07, amount_options)
    self.txtb(self.format_number(employee[:socialSecurityTaxWithheld], decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    y -= @box_height
    self.txtb(self.format_number(employee[:medicareWages], decimals: 2), 4.4, y, 1.8, @box_height - 0.07, amount_options)
    self.txtb(self.format_number(employee[:medicareTaxWithheld], decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    y -= @box_height
    self.txtb(self.format_number(0, decimals: 2), 4.4, y, 1.8, @box_height - 0.07, amount_options)
    self.txtb(self.format_number(0, decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    y -= @box_height
    self.txtb(self.format_number(0, decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    y -= @box_height
    self.txtb("#{employee[:firstName]} #{employee[:init]}", 0.5, y, 3.9, 3 * @box_height - 0.07, data_options)
    self.txtb(employee[:lastName], 2.4, y, 3.9, 3 * @box_height - 0.07, data_options)
    self.txtb(employee[:suffix], 4.05, y, 3.9, 3 * @box_height - 0.07, data_options)
    self.txtb(self.format_number(0, decimals: 2), 4.4, y, 1.8, @box_height - 0.07, amount_options)
    if employee[:insuranceOver50k] > 0
      self.txtb("C", 6.2, y, 0.55, @box_height - 0.07, amount_options.merge(h_align: :center))
      self.txtb(self.format_number(employee[:insuranceOver50k], decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    end
    y -= @box_height
    self.txtb("X", 4.7, y - 0.08, 0.12, 0.12, amount_options.merge(h_align: :center, v_align: :center, h_pad: 0, v_pad: 0)) if employee[:isStatutory]
    self.txtb("X", 5.2, y - 0.08, 0.12, 0.12, amount_options.merge(h_align: :center, v_align: :center, h_pad: 0, v_pad: 0)) if employee[:isRetirementPlan]
    if employee[:traditional401k] > 0
      self.txtb("D", 6.2, y, 0.55, @box_height - 0.07, amount_options.merge(h_align: :center))
      self.txtb(self.format_number(employee[:traditional401k], decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    end
    y -= @box_height
    if employee[:roth401k] > 0
      self.txtb("AA", 6.2, y, 0.55, @box_height - 0.07, amount_options.merge(h_align: :center))
      self.txtb(self.format_number(employee[:roth401k], decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    end
    y -= @box_height
    self.txtb("#{employee[:address]}\n#{employee[:city]}, #{employee[:state]} #{employee[:zip]}", 0.5, y + 0.05, 3.9, 3 * @box_height - 0.07, data_options)
    #self.txtb("D", 6.2, y, 0.55, @box_height - 0.07, amount_options.merge(h_align: :center))
    #self.txtb(self.format_number(0, decimals: 2), 6.2, y, 1.8, @box_height - 0.07, amount_options)
    y -= @box_height + @filler_height
    self.txtb(employee[:states][0][:code], 0.5, y, 0.5, @box_height - 0.07, data_options.merge(h_align: :center))
    self.txtb(@data[:stateIDs][employee[:states][0][:code].to_sym], 1, y, 1.9, @box_height - 0.07, data_options)
    self.txtb(self.format_number(employee[:states][0][:taxableWages], decimals: 2), 2.9, y, 1.1, @box_height - 0.07, amount_options)
    self.txtb(self.format_number(employee[:states][0][:stateTaxWithheld], decimals: 2), 4, y, 1.1, @box_height - 0.07, amount_options)
    self.txtb(self.format_number(employee[:localities][0][:grossWages], decimals: 2), 5.1, y, 1.1, @box_height - 0.07, amount_options)
    self.txtb(self.format_number(employee[:localities][0][:localTaxWithheld], decimals: 2), 6.2, y, 1.1, @box_height - 0.07, amount_options)
    self.txtb(@data[:localityDescriptions][employee[:localities][0][:code].to_sym], 7.3, y, 0.7, @box_height - 0.07, data_options)
    y -= @box_height
    if employee[:states].length > 1
      self.txtb(employee[:states][1][:code], 0.5, y, 0.5, @box_height - 0.07, data_options.merge(h_align: :center))
      self.txtb(@data[:stateIDs][employee[:states][1][:code].to_sym], 1, y, 1.9, @box_height - 0.07, data_options)
      self.txtb(self.format_number(employee[:states][1][:taxableWages], decimals: 2), 2.9, y, 1.1, @box_height - 0.07, amount_options)
      self.txtb(self.format_number(employee[:states][1][:stateTaxWithheld], decimals: 2), 4, y, 1.1, @box_height - 0.07, amount_options)
    end
    if employee[:localities].length > 1
      self.txtb(self.format_number(employee[:localities][1][:grossWages], decimals: 2), 5.1, y, 1.1, @box_height - 0.07, amount_options)
      self.txtb(self.format_number(employee[:localities][1][:localTaxWithheld], decimals: 2), 6.2, y, 1.1, @box_height - 0.07, amount_options)
      self.txtb(@data[:localityDescriptions][employee[:localities][1][:code].to_sym], 7.3, y, 0.7, @box_height - 0.07, data_options)
    end

  end

  # Draws instructions.
  def draw_instructions(y, opt)
    case opt
    when "B"
      left = File.read(Rails.root.join('lib', 'assets', 'text', 'w2_b_left.htm'))
      right = File.read(Rails.root.join('lib', 'assets', 'text', 'w2_b_right.htm'))
      self.txtb(left, 0.5, y, 3.65, 4.5, h_align: :left, v_align: :top, size: 8.5)
      self.txtb(right, 4.35, y, 3.65, 4.5, h_align: :left, v_align: :top, size: 8.5)
    when "C"
      left = File.read(Rails.root.join('lib', 'assets', 'text', 'w2_c_left.htm'))
      right = File.read(Rails.root.join('lib', 'assets', 'text', 'w2_c_right.htm'))
      self.txtb(left, 0.5, y, 3.65, 4.5, h_align: :left, v_align: :top, size: 8.5)
      self.txtb(right, 4.35, y, 3.65, 4.5, h_align: :left, v_align: :top, size: 8.5)
    when "2"
      left = File.read(Rails.root.join('lib', 'assets', 'text', 'w2_2_left.htm'))
      right = File.read(Rails.root.join('lib', 'assets', 'text', 'w2_2_right.htm'))
      self.txtb(left, 0.5, y, 3.65, 4.5, h_align: :left, v_align: :top, size: 8.5)
      self.txtb(right, 4.35, y, 3.65, 4.5, h_align: :left, v_align: :top, size: 8.5)
    end
  end

  # Draws W-2 box.
  def draw_box(y, opt)

    # Save initial y coordinate.
    save_y = y

    # Draw shaded boxes.
    self.rect(4.55, y - 5 * @box_height, 1.65, @box_height, line_color: nil, fill_color: "999999")
    self.rect(4.4, y - 0.12 - 5 * @box_height, 0.17, @box_height - 0.12, line_color: nil, fill_color: "999999")
    self.rect(6.2, y - 10 * @box_height, 1.8, @filler_height, line_color: nil, fill_color: "999999")

    # Draw horizontal lines.
    self.hline(0.5, y, 7.5)
    y -= @box_height
    self.hline(0.5, y, 7.5)
    y -= @box_height
    self.hline(0.5, y, 7.5)
    y -= @box_height
    self.hline(4.4, y, 3.6)
    y -= @box_height
    self.hline(4.4, y, 3.6)
    y -= @box_height
    self.hline(0.5, y, 7.5)
    y -= @box_height
    self.hline(0.5, y, 7.5)
    y -= @box_height
    self.hline(4.4, y, 3.6)
    y -= @box_height
    self.hline(4.4, y, 3.6)
    y -= @box_height
    self.hline(6.2, y, 1.8)
    y -= @box_height
    self.hline(6.2, y, 1.8)
    y -= @filler_height
    self.hline(0.5, y, 7.5)
    y -= @box_height
    self.dash([1])
    self.hline(0.5, y, 7.5)
    self.undash
    y -= @box_height
    self.hline(0.5, y, 7.5)

    # Draw vertical lines.
    y = save_y
    self.vline(0.5, y, 4)
    self.vline(8, y, 4)
    self.vline(2, y, @box_height)
    self.vline(3.7, y, @box_height)
    y -= @box_height
    self.vline(4.4, y, 9 * @box_height + @filler_height)
    self.vline(6.2, y, 11 * @box_height + @filler_height)
    y -= (5 * @box_height + 0.13)
    self.vline(6.7, y, @box_height - 0.13)
    y -= @box_height
    self.vline(6.7, y, @box_height - 0.13)
    y -= @box_height
    self.vline(6.7, y, @box_height - 0.13)
    y -= @box_height
    self.vline(6.7, y, @box_height - 0.13)
    y += 0.13
    y -= @box_height + @filler_height
    self.vline(1, y - 0.13, @box_height - 0.13)
    self.vline(2.9, y, 2 * @box_height)
    self.vline(4, y, 2 * @box_height)
    self.vline(5.1, y, 2 * @box_height)
    self.vline(7.3, y, 2 * @box_height)
    y -= @box_height
    self.vline(1, y - 0.13, @box_height - 0.13)

    # Draw text labels.
    y = save_y
    label_options = { h_align: :left, v_align: :top, h_pad: 0.05, v_pad: 0.025, size: 5.5 }
    self.txtb("<b>a</b>  Employee's social security number", 2, y, 1.7, @box_height, label_options)
    self.txtb("OMB No. 1545-0008", 3.7, y, 3, @box_height, label_options.merge(v_align: :bottom))
    y -= @box_height
    self.txtb("<b>b</b>  Employer identification number (EIN)", 0.5, y, 3.9, @box_height, label_options)
    self.txtb("<b>1</b>  Wages, tips, other compensation", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("<b>2</b>  Federal income tax withheld", 6.2, y, 1.8, @box_height, label_options)
    y -= @box_height
    self.txtb("<b>c</b>  Employer's name, address, and ZIP code", 0.5, y, 3.9, @box_height, label_options)
    self.txtb("<b>3</b>  Social security wages", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("<b>4</b>  Social security tax withheld", 6.2, y, 1.8, @box_height, label_options)
    y -= @box_height
    self.txtb("<b>5</b>  Medicare wages and tips", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("<b>6</b>  Medicare tax withheld", 6.2, y, 1.8, @box_height, label_options)
    y -= @box_height
    self.txtb("<b>7</b>  Social security tips", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("<b>8</b>  Allocated tips", 6.2, y, 1.8, @box_height, label_options)
    y -= @box_height
    self.txtb("<b>d</b>  Control number", 0.5, y, 3.9, @box_height, label_options)
    self.txtb("<b>9</b>", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("<b>10</b>  Dependent care benefits", 6.2, y, 1.8, @box_height, label_options)
    y -= @box_height
    self.txtb("<b>e</b>  Employee's first name and initial", 0.5, y, 3.9, @box_height, label_options)
    self.txtb("Last name", 2.4, y, 3.9, @box_height, label_options)
    self.txtb("Suff.", 4.05, y, 3.9, @box_height, label_options)
    self.txtb("<b>11</b>  Nonqualified plans", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("<b>12a</b>  See instructions for box 12", 6.2, y, 1.8, @box_height, label_options)
    self.txtb("C\no\nd\ne", 6.2, y - 0.11, 0.15, @box_height - 0.1, label_options.merge(h_align: :center, v_align: :top, h_pad: 0, v_pad: 0, size: 3))
    y -= @box_height
    self.txtb("<b>13</b>", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("Statutory\nemployee", 4.7, y, 0.5, @box_height, label_options.merge(size: 4, h_pad: 0))
    self.txtb("Retirement\nplan", 5.2, y, 0.5, @box_height, label_options.merge(size: 4, h_pad: 0))
    self.txtb("Third-party\nsick pay", 5.7, y, 0.5, @box_height, label_options.merge(size: 4, h_pad: 0))
    self.rect(4.7, y - 0.17, 0.12, 0.12, line_width: 0.005)
    self.rect(5.2, y - 0.17, 0.12, 0.12, line_width: 0.005)
    self.rect(5.7, y - 0.17, 0.12, 0.12, line_width: 0.005)
    self.txtb("<b>12b</b>", 6.2, y, 1.8, @box_height, label_options)
    self.txtb("C\no\nd\ne", 6.2, y - 0.11, 0.15, @box_height - 0.1, label_options.merge(h_align: :center, v_align: :top, h_pad: 0, v_pad: 0, size: 3))
    y -= @box_height
    self.txtb("<b>14</b>  Other", 4.4, y, 1.8, @box_height, label_options)
    self.txtb("<b>12c</b>", 6.2, y, 1.8, @box_height, label_options)
    self.txtb("C\no\nd\ne", 6.2, y - 0.11, 0.15, @box_height - 0.1, label_options.merge(h_align: :center, v_align: :top, h_pad: 0, v_pad: 0, size: 3))
    y -= @box_height
    self.txtb("<b>f</b>  Employee's address and ZIP code", 0.5, y, 3.9, @box_height + @filler_height, label_options.merge(v_align: :bottom))
    self.txtb("<b>12d</b>", 6.2, y, 1.8, @box_height, label_options)
    self.txtb("C\no\nd\ne", 6.2, y - 0.11, 0.15, @box_height - 0.1, label_options.merge(h_align: :center, v_align: :top, h_pad: 0, v_pad: 0, size: 3))
    y -= @box_height + @filler_height
    self.txtb("<b>15</b>  State", 0.5, y, 0.5, @box_height, label_options)
    self.txtb("Employer's state ID number", 1.05, y, 1.8, @box_height, label_options)
    self.txtb("<b>16</b>  State wages, tips, etc.", 2.9, y, 1.1, @box_height, label_options)
    self.txtb("<b>17</b>  State income tax", 4, y, 1.1, @box_height, label_options)
    self.txtb("<b>18</b>  Local wages, tips, etc.", 5.1, y, 1.1, @box_height, label_options)
    self.txtb("<b>19</b>  Local income tax", 6.2, y, 1.1, @box_height, label_options)
    self.txtb("<b>20</b>  Locality name", 7.3, y, 0.7, @box_height, label_options)
    y -= 2 * @box_height
    self.txtb("<b>Form<b>", 0.5, y, 7.5, 0.4, label_options.merge(v_align: :center, h_pad: 0))
    self.txtb("<b>W-2<b>", 0.75, y, 7.5, 0.4, label_options.merge(v_align: :center, h_pad: 0, size: 20))
    self.txtb("<b>Wage and Tax Statement<b>", 1.5, y, 7.5, 0.4, label_options.merge(v_align: :center, h_pad: 0, size: 10))
    self.txtb("<b>2021<b>", 4, y, 1.1, 0.4, label_options.merge(v_align: :center, h_align: :center, h_pad: 0, size: 18, font: "SF Mono"))
    self.txtb("Department of the Treasury — Internal Revenue Service", 0.5, y, 7.5, @box_height, label_options.merge(h_align: :right, h_pad: 0))

    # Draw special information for different formats.
    y = save_y
    case opt
    when "B"
      self.hline(2, y, 1.7, line_width: 0.03)
      self.hline(2, y - @box_height, 1.7, line_width: 0.03)
      self.hline(4.4, y - @box_height, 3.6, line_width: 0.03)
      self.hline(4.4, y - 2 * @box_height, 3.6, line_width: 0.03)
      self.vline(2, y, @box_height, line_width: 0.03)
      self.vline(3.7, y, @box_height, line_width: 0.03)
      self.vline(4.4, y - @box_height, @box_height, line_width: 0.03)
      self.vline(6.2, y - @box_height, @box_height, line_width: 0.03)
      self.vline(8, y - @box_height, @box_height, line_width: 0.03)
      self.txtb("<b>Safe, accurate,\nFAST! Use</b>", 4.8, y, 1, @box_height, label_options.merge(v_align: :center, h_pad: 0))
      self.standard_graphic("efile", 5.5, y, 1.05, @box_height, v_align: :center)
      self.txtb("Visit the IRS website at\n<i>www.irs.gov/efile</i>", 6.75, y, 1.75, @box_height, label_options.merge(v_align: :center, h_pad: 0))
      self.txtb("<b>Copy B — To Be Filed With Employee's FEDERAL Tax Return.</b>\nThis information is being furnished to the Internal Revenue Service.", 0.5, y - 4.4, 7.5, 0.3, label_options.merge(v_align: :center, h_pad: 0, size: 8))
    when "C"
      self.txtb("This information is being furnished to the Internal Revenus Service. If you\nare required to file a tax return, a negligence penalty or other sanction\nmay be imposed on you if this income is taxable and you fail to report it.", 5.2, y, 2.5, @box_height, label_options.merge(v_align: :center, h_pad: 0))
      self.txtb("<b>Copy C — For EMPLOYEE'S RECORDS</b>\n(See <i>Notice to Employee</i> on the back of Copy B.)", 0.5, y - 4.4, 7.5, 0.3, label_options.merge(v_align: :center, h_pad: 0, size: 8))
      self.txtb("<b>Safe, accurate,\nFAST! Use</b>", 6.3, y - 4.2, 1, 0.25, label_options.merge(v_align: :center, h_pad: 0))
      self.standard_graphic("efile", 6.95, y - 4.2, 1.05, 0.25, v_align: :center, h_align: :right)
    when "2"
      self.txtb("<b>Copy 2 — To Be Filed With Employee's State, City, or Local\nIncome Tax Return</b>", 0.5, y - 4.4, 7.5, 0.3, label_options.merge(v_align: :center, h_pad: 0, size: 8))
    when "1"
      self.txtb("<b>Copy 1 — For State, City, or Local Tax Department</b>", 0.5, y - 4.4, 7.5, 0.3, label_options.merge(v_align: :center, h_pad: 0, size: 8))
    end

  end

end