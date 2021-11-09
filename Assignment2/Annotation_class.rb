require './common_functions.rb' 
require 'json'
require 'rest-client'

class Annotation
  
  # Class to hold information about the annotations and annotate
  
  attr_accessor :data
  attr_accessor :id
  attr_accessor :url
  attr_accessor :annotations

  
  @@togows_url = 'http://togows.org/entry/ebi-uniprot/' 
  @@dr_json = '/dr.json'
  
  def initialize(params={})
    
    @id = params.fetch(:id)
    @url = @@togows_url + @id.to_s + @@dr_json
    res = fetch(@url)
    if res
      @data = JSON.parse(res.body)[0] # data holds information about the gene id in many databases.
    else
      puts "Web call failed"
    end
    @annotations = {}
  end
  
  
  def go # Gene ontology
    go_data = @data["GO"]
    p_exp = /P:/ # P for process.
    actual_process = /[0-9a-zA-Z\s]+$/
    gene_ontologies = []
    if go_data.nil?
      @annotations[:GO] = []
      return
    end
    
    go_data.each { |go|
      if p_exp.match go[1]
        process = [go[0]]
        process << [actual_process.match(go[1])[0]]
        gene_ontologies |= [ process.join(";") ]
      end
      }
    @annotations[:GO] = gene_ontologies
  end

  
  def kegg # Kegg pathway
    kegg_data = @data["KEGG"]
    kegg_data = kegg_data[0] if kegg_data.is_a? Array # kegg data may be an array of arrays
    kegg_data = kegg_data[0] if kegg_data.is_a? Array
    kegg_url = "http://togows.org/entry/kegg-genes/#{kegg_data}/pathways.json"
    res = fetch(kegg_url)
    if res
      data = JSON.parse(res.body)
      unless data[0].empty?
        unless data[0].nil?
          @annotations[:KEGG] = data[0]
        end
        
      end
    else
      puts "Web call failed."
    end
  end
  
  
  def general_use(key) # Annotate the gene with the specified key if it exists.
    unless @data.keys.include? key
      puts "#{key} is not among the togows ebi-uniprot keys."
      return
    end
    general_data = @data[key]
    @annotations[key.to_sym] = general_data
    
  end
  
end