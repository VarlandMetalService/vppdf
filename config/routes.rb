Rails.application.routes.draw do

  # Set root.
  root 'pdf#index'

  # Set up routes for PDFs. Allow GET or POST.
  match "/emp9x12" => "pdf#employee_envelopes", via: [:post, :get]
  match "/sample" => "pdf#sample", via: [:post, :get]
  match "/w2" => "pdf#w2", via: [:post, :get]
  match "/signature_sampler" => "pdf#signature_sampler", via: [:post, :get]
  match "/bakesheet" => "pdf#bakesheet", via: [:post, :get]
  match "/shipper" => "pdf#shipper", via: [:post, :get]
  match "/bill_of_lading" => "pdf#bill_of_lading", via: [:post, :get]
  match "/invoice" => "pdf#invoice", via: [:post, :get]
  match "/quote" => "pdf#quote", via: [:post, :get]
  match "/statement" => "pdf#statement", via: [:post, :get]
  match "/statement/:customer" => "pdf#statement", via: [:post, :get]
  match "/po" => "pdf#po", via: [:post, :get]
  match "/timecards" => "pdf#timecards", via: [:post, :get]
  match "/inventory_worksheet" => "pdf#inventory_worksheet", via: [:post, :get]
  match "/inventory_edit_report" => "pdf#inventory_edit_report", via: [:post, :get]
  match "/inventory_single_cost_center_variation_report" => "pdf#inventory_single_cost_center_variation_report", via: [:post, :get]
  match "/inventory_multiple_cost_center_variation_report" => "pdf#inventory_multiple_cost_center_variation_report", via: [:post, :get]

  match "/ap_checks/:start/:end" => "pdf#ap_checks", via: [:post, :get]

  match "/en_report/:year/:month/:day" => "pdf#en_report", via: [:post, :get]
  match "/en_report" => "pdf#en_report", via: [:post, :get]

end