class PdfController < ApplicationController

  def signature_sampler
    self.send_pdf(SignatureSampler.new(params[:name]), 'SignatureSampler')
  end

  def bill_of_lading
    bill = BillOfLading.new(params[:timestamp], params[:ip_address])
    if params[:autoprint]
      self.print_file(bill, bill.user, bill.ip, "BillOfLading", "BoL #{bill.shipper}")
      render(status: 200, json: "")
    else
      self.send_pdf(bill, "BoL #{bill.shipper}")
    end
  end

  def shipper
    shipper = Shipper.new(params[:shipper])
    if params[:autoprint]
      self.print_file(shipper, params[:user], params[:ip_address], "PackingSlip", "PS ##{params[:shipper]}")
      render(status: 200, json: "")
    else
      self.send_pdf(shipper, "PS ##{params[:shipper]}")
    end
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

  # Sends PDF to browser window.
  def send_pdf(pdf, name)
    send_data pdf.render,
              filename: "#{name}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
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