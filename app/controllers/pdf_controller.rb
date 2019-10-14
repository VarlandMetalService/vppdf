class PdfController < ApplicationController

  def signature_sampler
    self.send_pdf(SignatureSampler.new(params[:name]), 'SignatureSampler')
  end

  def bill_of_lading
    bill = BillOfLading.new(params[:timestamp], params[:ip_address])
    self.print_or_display(bill, "BoL #{bill.shipper}", user: bill.user, ip: bill.ip)
  end

  def shipper
    shipper = Shipper.new(params[:shipper])
    self.print_or_display(shipper, "PS ##{params[:shipper]}", type: "PackingSlip")
  end

  def quote
    quote = Quote.new(params[:start_quote], params[:end_quote])
    desc = "Quote ##{params[:start_quote]}"
    desc << "-#{params[:end_quote]}" unless params[:end_quote].blank?
    self.print_or_display(quote, desc)
  end

  def invoice
    invoice = Invoice.new(params[:invoice])
    self.print_or_display(invoice, "Invoice ##{params[:invoice]}")
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

  def index
    render(layout: false)
  end

protected

  # Prints if autoprint parameter given, otherwise sends to screen.
  def print_or_display(file, description, options = {})
    user = options.fetch(:user, params[:user])
    ip = options.fetch(:ip, params[:ip_address])
    type = options.fetch(:type, file.class)
    if params[:autoprint]
      self.print_file(file, user, ip, type, description)
      render(status: 200, json: "")
    else
      self.send_pdf(file, description)
    end
  end

  # Sends PDF to browser window.
  def send_pdf(pdf, name)
    send_data(pdf.render,
              filename: "#{name}.pdf",
              type: 'application/pdf',
              disposition: 'inline')
  end

  # Sends PDF file to print queueing software.
  def print_file(file, user, ip, type, description)
    job = {
      file: "data:application/pdf;base64,#{Base64.encode64(file.render)}",
      user: user,
      ip_address: ip,
      document_type: type,
      description: description
    }
    uri = URI.parse("http://vms.varland.com/print_jobs")
    Net::HTTP.post_form(uri, {"data" => JSON.generate(job)})
  end

end