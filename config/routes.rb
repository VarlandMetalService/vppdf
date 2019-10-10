Rails.application.routes.draw do
  
  # Set up routes for PDFs. Allow GET or POST.
  match "/sample" => "pdf#sample", via: [:post, :get]
  match "/signature_sampler" => "pdf#signature_sampler", via: [:post, :get]
  match "/purchase_order" => "pdf#purchase_order", via: [:post, :get]
  match "/bakesheet" => "pdf#bakesheet", via: [:post, :get]
  match "/shipper" => "pdf#shipper", via: [:post, :get]
  match "/bill_of_lading" => "pdf#bill_of_lading", via: [:post, :get]
  match "/invoice" => "pdf#invoice", via: [:post, :get]

end