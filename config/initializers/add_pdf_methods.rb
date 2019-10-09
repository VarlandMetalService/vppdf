class Integer < Numeric
  def pt
    return (self.to_i / 72.0).to_f
  end
end