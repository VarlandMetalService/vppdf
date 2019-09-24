class PdfController < ApplicationController

  def purchase_order
    self.send_pdf(PurchaseOrder.new)
  end

  def sample
    self.send_pdf(Sample.new)
  end

protected

  def send_pdf(pdf)
    send_data pdf.render,
              filename: 'Sample.pdf',
              type: 'application/pdf',
              disposition: 'inline'
  end

end