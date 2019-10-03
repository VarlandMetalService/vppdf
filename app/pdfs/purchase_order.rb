# Class for printing purchase order from System i.
class PurchaseOrder < VarlandPdf

  # Default page orientation for Varland documents. May be overridden in child classes.
  PAGE_ORIENTATION = :landscape

  # Default letterhead format. May be overridden in child classes.
  LETTERHEAD_FORMAT = :landscape

  # Constructor.
  def initialize

    # Call parent constructor.
    super()

  end

end