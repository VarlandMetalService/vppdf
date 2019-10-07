class PdfController < ApplicationController

  def shipper
    self.send_pdf(Shipper.new(params[:shipper]), 'Shipper')
  end

  def purchase_order
    self.send_pdf(PurchaseOrder.new, 'PurchaseOrder')
  end

  def sample
    self.send_pdf(Sample.new, 'Sample')
  end

  def bakesheet
    self.send_pdf(Bakesheet.new, 'Bakesheet')
  end

protected

  def send_pdf(pdf, name)
    send_data pdf.render,
              filename: "#{name}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

end