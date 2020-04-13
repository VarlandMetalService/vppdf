require 'net/ftp'

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
    quote = Quote.new(params[:quote])
    desc = "Quote ##{params[:quote]}"
    self.save_to_ftp(quote, params[:quote].to_s, "192.168.82.5", "admin", "Vms.1946!", "/PCDATA/Sales/QuotePDFs/")
    self.print_or_display(quote, desc)
  end

  def po
    po = PurchaseOrder.new(params[:po])
    self.print_or_display(po, "PO ##{params[:po]}")
  end

  def inventory_worksheet
    pdf = InventoryWorksheet.new(params[:account])
    self.print_or_display(pdf, "Inventory Worksheet")
  end

  def inventory_edit_report
    pdf = InventoryEditReport.new(params[:account])
    self.print_or_display(pdf, "Inventory Edit Report")
  end

  def inventory_single_cost_center_variation_report
    pdf = InventorySingleCostCenterVariationReport.new(params[:account])
    self.print_or_display(pdf, "Inventory Single Cost Center Variation Report")
  end

  def inventory_multiple_cost_center_variation_report
    pdf = InventoryMultipleCostCenterVariationReport.new(params[:account])
    self.print_or_display(pdf, "Inventory Multiple Cost Center Variation Report")
  end

  def invoice
    invoice = Invoice.new(params[:invoice])
    self.print_or_display(invoice, "Invoice ##{params[:invoice]}")
  end

  def sample
    self.send_pdf(Sample.new, 'Sample')
  end

  def bakesheet
    self.send_pdf(Bakesheet.new, 'Bakesheet')
  end

  def timecards
    self.send_pdf(Timecards.new(params[:period], params[:easter]), 'Timecards')
  end

  def index
    render(layout: false)
  end

protected

  # Saves file to FTP server.
  def save_to_ftp(file, name, server, user, pass, path)
    Net::FTP.open(server, user, pass) do |ftp|
      ftp.passive = true
      ftp.chdir(path)
      ftp.storbinary("STOR #{name}.pdf", StringIO.new(file.render), Net::FTP::DEFAULT_BLOCKSIZE)
    end
  end

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