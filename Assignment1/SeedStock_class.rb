class SeedStock
  
  attr_accessor :Seed_stock       # "attribute accessor" for "@Seed_stock"
  attr_accessor :Mutant_Gene_ID   # "attribute accessor" for "@Mutant_Gene_ID"
  attr_accessor :Last_Planted     # "attribute accessor" for "@Last_Planted"
  attr_accessor :Storage          # "attribute accessor" for "@Storage"
  attr_accessor :Grams_Remaining  # "attribute accessor" for "@Grams_Remaining"
    

  def initialize(params={})
    
    @Seed_stock = params.fetch(:seed_stock, "Unknown")
    @Mutant_Gene_ID = params.fetch(:mutant_gene_id, "Unknown")
    @Last_Planted = params.fetch(:last_planted, "Date_unknown")
    @Storage = params.fetch(:storage, "Unknown")
    @Grams_Remaining = params.fetch(:grams_remaining, 0000)
    
  end
  
  
  def plant(value)
    
    # Source: https://www.rubyguides.com/2015/12/ruby-time/
    require 'date'
    unless @Grams_Remaining-value <= 0
      puts "We have planted #{value} seeds of Seed Stock #{@Seed_stock}"
      @Grams_Remaining-=value
    else
      @Grams_Remaining=0
      puts "WARNING: we have run out of Seed Stock '#{@Seed_stock}'"
    end
    @Last_Planted = Date.today.to_s
  end
  
  
end