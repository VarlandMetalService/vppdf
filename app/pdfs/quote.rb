# Class for printing quote from System i.
class Quote < VarlandPdf

  # Use letterhead.
  LETTERHEAD_FORMAT = :portrait
  
  # Constructor.
  def initialize(quote = nil)

    # Call parent constructor.
    super()

    # Load data.
    if quote.blank?
      self.load_sample_data
    else
      @quote = quote
      self.load_data
    end

  end
  
  # Loads sample data.
  def load_sample_data
    @data = self.load_sample("quote")
  end

  # Loads json data.
  def load_data
    @data = self.load_json("http://as400railsapi.varland.com/v1/quote?quote=#{@quote}")
  end

end