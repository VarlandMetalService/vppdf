Rails.application.routes.draw do
  
  # Set up routes for PDFs. Allow GET or POST.
  match "/sample" => "pdf#sample", via: [:post, :get]
  match "/purchase_order" => "pdf#purchase_order", via: [:post, :get]
  match "/bakesheet" => "pdf#bakesheet", via: [:post, :get]
  match "/certification" => "pdf#certification", via: [:post, :get]

end