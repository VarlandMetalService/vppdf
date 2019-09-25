class PdfController < ApplicationController

  def purchase_order
    self.send_pdf(PurchaseOrder.new, 'PurchaseOrder')
  end

  def sample
    self.send_pdf(Sample.new, 'Sample')
  end

protected

  def send_pdf(pdf, name)
    send_data pdf.render,
              filename: "#{name}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

end