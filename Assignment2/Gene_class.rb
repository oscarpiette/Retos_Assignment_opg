require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Interaction_class.rb' 


class Gene
  

  attr_accessor :id                # "attribute accessor" for "@id"
  attr_accessor :partners          # "attribute accessor" for "@partners"
  attr_accessor :interactions      # "attribute accessor" for "@interactions"
  attr_accessor :initial           # "attribute accessor" for "@initial"
  
  @@all_genes = {}
  @@network_genes = []
  @@network_interactions = []
  
  
  def initialize(params={})
    
    @initial = params.fetch(:initial)
    @id = params.fetch(:id)
    @@network_genes |= [@id]
    
    @partners = params.fetch(:partners)
    @interactions = params.fetch(:interactions)
    @@network_interactions << [@interactions] # las interacciones pueden ser de ambos sentidos: <<
    
    @@all_genes[id.to_sym] = self
    
    @partners = [@partners] unless @partners.is_a? Array
    #@partners = update_partners
  end
    
  
  def Gene.get_gene(id)
    return @@all_genes[id.to_sym]
  end
  
  
  def update_partners
    new_partners = []
    
    # Filter if the genes are already gene objects
    all_classes = []
    @partners.each { |partner|
      if partner.is_a? String
        all_classes << false
      elsif partner.is_a? Gene
        all_classes << true
      else
        all_classes << false
      end
      
      }
    
    if all_classes.all?
        return @partners
    end
    
    @partners.each {|partner|
      if Gene.get_gene(partner) # if the gene object with the partner id exists, add it to the @partners list
        new_partners |= [Gene.get_gene(partner)]
      else # if it doesnt exist, create and add it to the @partners list
        new_partners |= [Gene.new({id: partner,
                               partners: @id,
                               interactions: Interaction.get_interactions(@id, partner)})]
      end
      }
    return new_partners
  end
  
  
  def Gene.get_network_genes
    return @@network_genes
  end
  
  
  def Gene.get_network_interactions
    return @@network_interactions
  end
  
  
  def Gene.get_all_genes
    return @@all_genes
  end
end
