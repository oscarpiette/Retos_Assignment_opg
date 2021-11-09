require './Interaction_class.rb' 
require './common_functions.rb' 
require './Annotation_class.rb' 
require 'json'
require 'rest-client'

class Gene
  
  # Class to hold the information associated with each gene
  attr_accessor :id                # "attribute accessor" for "@id"
  attr_accessor :partners          # "attribute accessor" for "@partners"
  attr_accessor :interactions      # "attribute accessor" for "@interactions"
  attr_accessor :level             # "attribute accessor" for "@level"
  attr_accessor :annotations       # "attribute accessor" for "@annotations"
  @@all_genes = {}
  
  def initialize(params={})
    @annotations = {}
    @level = params.fetch(:level)
    @id = params.fetch(:id)
    @partners = params.fetch(:partners)
    @interactions = params.fetch(:interactions)
    @partners = [@partners] unless @partners.is_a? Array
    @@all_genes[@id.to_sym] = self
  end
    
  
  def Gene.get_gene(id) # Access an individual gene
    return @@all_genes[id.to_sym]
  end
  
  
  def Gene.get_all_genes
    return @@all_genes
  end
  
  
  def annotate_go # Function to annotate the gene ontology.
    if @annotations.is_a? Hash
      @annotations = Annotation.new({id: @id}) # Uses the general annotation class
    end
    annotation_list = @annotations.go
    @annotations.annotations[:GO] = annotation_list
  end
  
  
  def annotate_kegg # Function to annotate the kegg pathways associated with this gene
    if @annotations.is_a? Hash
      @annotations = Annotation.new({id: @id}) # Uses the general annotation class
    end
    annotation_list = @annotations.kegg
    @annotations.annotations[:KEGG] = annotation_list
  end
  
  
  def general_annotation(key) # Funtion to annotate any other information
    if @annotations.is_a? Hash
      @annotations = Annotation.new({id: @id}) # Uses the general annotation class
    end
    annotation_list = @annotations.general_use(key)
    unless annotation_list.nil?
      @annotations.annotations[key.to_sym] = annotation_list
    end
  end
  
  
end
