class Interaction
  

  #attr_accessor :interactorA  # "attribute accessor" for "@interactorA"
  #attr_accessor :interactorB  # "attribute accessor" for "@interactorB"
  attr_accessor :interactors  # "attribute accessor" for "@interactors"
  attr_accessor :quality      # "attribute accessor" for "@quality"
  @@all_interactions = []

  
  def initialize(params={})
    
    #@interactorA = params.fetch(:interactorA)
    #@interactorB = params.fetch(:interactorB)
    @interactors = params.fetch(:interactors)
    @quality = params.fetch(:quality)
    @@all_interactions |= [self]
    
  end
  
  
  def Interaction.get_interactions(id1, id2)
    
    both = [id1, id2]
    results = []
    @@all_interactions.each { |int|
      if both.include? int.interactors[0] and both.include? int.interactors[1]
        results |= [int]
      end
      }
    return results.compact
  
  end
  
end