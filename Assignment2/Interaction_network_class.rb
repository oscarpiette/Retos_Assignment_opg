require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Intact_querry_class.rb' 
require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Gene_class.rb' 


class Interaction_network < Gene
  
  @@all_networks = []
  attr_accessor :proteins  # "attribute accessor" for "@algo"
  attr_accessor :interactions  # "attribute accessor" for "@algo"

    
  def initialize(params={})
    super(params)
    @proteins = []
    @interactions = []
  end
  
  
  def Interaction_network.valid_interactions?(ids)
    
    if ids.length != 2
      puts "Warning, Interaction_network takes as an argument a list of exactly 2 gene ids"
      return 
    end
    
    geneA = Intact_querry.get_querry(ids[0])
    geneB = Intact_querry.get_querry(ids[1])
    
    unless geneA 
        puts "Warning, querry of gene id #{ids[0]} was not yet executed"
        return
    end
    
    unless geneB 
        puts "Warning, #{ids[1]} are not (yet) defined"
        return
    end
    
    # aqui tengo que sacar los partners de geneA y de geneB, y ver si estan incluidos uno dentro del otro
    
    if geneA.partners.include? ids[1] and geneB.partners.include? ids[0]
        puts "There is an interaction between #{ids[0]} and #{ids[1]}"
        return true
    end
    return false
    
  end
  
  
  def create_network
    
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
   
  
end