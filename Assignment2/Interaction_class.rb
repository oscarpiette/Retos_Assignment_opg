class Interaction
  # Class to hold each interaction

  attr_accessor :interactors  # "attribute accessor" for "@interactors"
  attr_accessor :quality      # "attribute accessor" for "@quality"
  @@all_interactions = []

  
  def initialize(params={})
    
    @interactors = params.fetch(:interactors)
    @quality = params.fetch(:quality)
    @@all_interactions |= [self]
    
  end
  
  
  def Interaction.get_interactions(id1, id2=nil) # get all interactions of 1 gene, or the interaction between 2 genes.
    unless id2
      results = []
      @@all_interactions.each { |int|
        if int.interactors.include? id1
          results |= [int]
        end
        }
      return results.compact
    end
    
    both = [id1, id2]
    results = []
    @@all_interactions.each { |int|
      if both.include? int.interactors[0] and both.include? int.interactors[1]
        results |= [int]
      end
      }
    return results.compact
  
  end
  
  
  def ==(object) # Method to check if 2 interaction objects are the same.
    unless object.respond_to? :interactors
      $stderr.puts "Warning, == only viable for objects of the same class"
      return
    end
    
    if @interactors.include? object.interactors[0] and @interactors.include? object.interactors[1]
      return true
    else
      return false
    end
  end
  
  
  def include?(value) # method to check if an interaction includes a gene
    if @interactors.include? value
      return true
    else
      return false
    end
    
  end

end