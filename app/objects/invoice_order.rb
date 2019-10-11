class InvoiceOrder

  # Define public attributes.
  attr_reader :total,
              :shipper,
              :shop_order,
              :ship_date,
              :pounds,
              :pieces,
              :pounds_remaining,
              :pieces_remaining,
              :part_id,
              :sub_id,
              :process_code,
              :part_name,
              :process_specification,
              :is_complete,
              :purchase_orders,
              :remarks,
              :pricing_labels,
              :pricing_amounts,
              :lines_required,
              :miscellaneous_invoice,
              :freight_invoice

  # Constructor. Accepts order JSON.
  def initialize(order)

    # Store JSON.
    @order = order

    # Determine if miscellaneous or freight invoice.
    @miscellaneous_invoice = (@order[:part_id] == "MISCELLANEOUS INV")

    # Store attributes.
    self.store_order_attributes

    # Format pricing columns.
    self.format_pricing_columns

    # Calculate lines required.
    self.calc_lines_required

  end

  # Stores order attributes.
  def store_order_attributes

    # Store attributes.
    @total = @order[:total]
    @shipper = nil
    unless @miscellaneous_invoice || @order[:shipper] == 9999999999
      @shipper = @order[:shipper]
    end
    @shop_order = nil
    unless @miscellaneous_invoice || @order[:shop_order] == 9999999999
      @shop_order = @order[:number]
    end
    @ship_date = @order[:ship_date] ? Time.iso8601(@order[:ship_date]).strftime("%m/%d/%y") : nil
    @pounds = @order[:pounds]
    @pieces = @order[:pieces]
    @pounds_remaining = @order[:pounds_remaining]
    @pieces_remaining = @order[:pieces_remaining]
    @part_id = @miscellaneous_invoice ? nil : @order[:part_id]
    @sub_id = @order[:sub_id]
    @process_code = @order[:process_code]
    @part_name = @order[:part_name].reject(&:empty?)
    @process_specification = @order[:process_specification].reject(&:empty?)
    @is_complete = @order[:is_complete]
    @purchase_orders = @order[:purchase_orders].reject(&:empty?)

  end

  # Calculates lines required.
  def calc_lines_required

    # Get sum of part ID, name, and process spec.
    col_4_lines = 1 + @order[:part_name].length + @order[:process_specification].length
                
    # Return max of column 1, column 4, and columns 6 & 7.
    @lines_required = [6, col_4_lines, @pricing_amounts.length].max

    # # If order has remarks, add lines.
    # @order[:remarks] = @order[:remarks].reject(&:empty?)
    # @remarks = @order[:remarks]
    # unless @order[:remarks].length == 0
    #   @lines_required += @order[:remarks].length + 1
    # end

  end

  # Formats pricing columns.
  def format_pricing_columns

    # Initialize.
    @pricing_labels = []
    @pricing_amounts = []

    # Calculate extension price. Add to arrays unless 0.
    extension = @order[:extension_price]
    if @order[:is_complete] && !@order[:is_minimum]
      extension -= @order[:setup_charge]
    end
    unless extension == 0
      @pricing_labels << self.format_unit_price
      @pricing_amounts << extension
    end

    # Check extra fields unless miscellaneous invoice.
    unless @miscellaneous_invoice

      # Add setup charge if necessary.
      if @order[:is_complete] && !@order[:is_minimum] && @order[:setup_charge] != 0
        @pricing_labels << "#{@order[:setup_description]} CHARGE"
        @pricing_amounts << @order[:setup_charge]
      end

      # Add other charge if necessary. Uses & removes first line of remarks as label.
      if @order[:other_charge] != 0
        @pricing_labels << @order[:remarks].shift
        @pricing_amounts << @order[:other_charge]
      end

      # Add discount if necessary.
      total_discount = @order[:trade_discount] + @order[:quantity_discount]
      if total_discount != 0
        @pricing_labels << "DISCOUNT"
        @pricing_amounts << total_discount
      end

      # Add sales tax if necessary.
      if @order[:sales_tax] != 0
        @pricing_labels << "SALES TAX"
        @pricing_amounts << @order[:sales_tax]
      end

      # Add prepaid amount if necessary.
      if @order[:prepaid_amount] != 0
        @pricing_labels << "PREPAID"
        @pricing_amounts << @order[:prepaid_amount]
      end

      # Add blanket surcharge if necessary.
      if @order[:blanket_surcharge][:amount] != 0
        @pricing_labels << @order[:blanket_surcharge][:description]
        @pricing_amounts << @order[:blanket_surcharge][:amount]
      end

      # Add total surcharge if necessary,
      if @order[:surcharge_amount] != 0
        @pricing_labels << @order[:surcharge_description]
        @pricing_amounts << @order[:surcharge_amount]
      end

    end

    # Add total line.
    @pricing_labels << "TOTAL " + (@order[:total] < 0 ? "CREDIT" : "DUE")
    @pricing_amounts << @order[:total]

  end

  # Formats unit price.
  def format_unit_price

    # If minimum order, return lot charge/minimum label.
    if @order[:is_minimum]
      return (@order[:unit_price] == 0 ? "LOT CHARGE APPLIED" : "MINIMUM CHARGE")
    end

    # Round unit price to 2..5 decimals.
    price = self.format_number(@order[:unit_price],
                               decimals: 5,
                               delimiter: nil,
                               strip_insignificant_zeros: true)
    count_decimals = (price.include?('.') ? price.split('.').last.size : 0)
    if count_decimals < 2
      price = self.format_number(price.to_f, decimals: 2, delimiter: nil)
    end

    # Define labels for price per codes.
    labels = {
      "#": "/LB",
      C: "/CWT",
      E: "/EACH",
      M: "/M PCS"
    }

    # Return unit price.
    return "$#{price}#{labels[@order[:price_per].to_sym]}"

  end

  protected
  
    # Reference Rails helpers.
    def helpers
      ApplicationController.helpers
    end

    # Formats number.
    def format_number(number, options = {})

      # Load default options.
      decimals = options.fetch(:decimals, 0)
      delimiter = options.fetch(:delimiter, ",")
      strip_insignificant_zeros = options.fetch(:strip_insignificant_zeros, false)

      # Return formatted number.
      return self.helpers.number_with_precision(number,
                                                precision: decimals,
                                                delimiter: delimiter,
                                                strip_insignificant_zeros: strip_insignificant_zeros)

    end

end