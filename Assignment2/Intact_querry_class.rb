require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/main.rb'
require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Interaction_class.rb'
require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Gene_class.rb' 


class Intact_querry
  
  # url = adress + id + format
  @@adress = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/"
  @@format = "?format=tab25"
  @@all_querries = {}
  @@unsuccesful_querries = []
  attr_accessor :id             # "attribute accessor" for "@id"
  attr_accessor :body           # "attribute accessor" for "@body"
  attr_accessor :url            # "attribute accessor" for "@url"
  attr_accessor :interactions   # "attribute accessor" for "@interactions"
  attr_accessor :partners       # "attribute accessor" for "@partners"

    
  def initialize(params={})
    @id = params.fetch(:id)
    @url = @@adress + @id + @@format
    res = fetch(@url)
    @@threshold = params.fetch(:threshold, 0.20)
    @interactions = []
    @partners = []
    @print = params.fetch(:print, true)

    if res  
      body = res.body
      if @print
        puts "=====================\nInteraction querry of gene id #{@id}: \n"
      end
      @body = body.split("\n") # Separate the interaction lines
      @body.each {|line|
        if @print
            puts "---------------------"
        end
        *rest, quality = line.split("\t")
        
        interactorA, interactorB = get_locus_name(rest, @print)
        quality = quality.match(/\d.+/)[0].to_f
        
        # Filters:
        unless [interactorA, interactorB].all?
          next
        end
        
        unless quality >= @@threshold
          if @print
            puts "Warning, interaction with quality lower than threshold (#{@@threshold}) detected and ignored"
          end
          next
        end
        
        unless interactorA != interactorB
          if @print
            puts "Warning, an interaction with itself was detected and omitted"
          end
          next
        end
        
        if interactorB.downcase == @id.downcase # reverse the order to have first id be the querry id
          interactorA, interactorB = interactorB, interactorA
        end
        
        unless @partners.include? interactorB
          inter = Interaction.new({interactors: [interactorA, interactorB],
                                   quality: quality})
          @interactions |= [inter]
          @partners << interactorB
          if @print
            puts "#{inter.interactors[0]} - #{inter.interactors[1]}"
            puts "Quality of interaction: #{inter.quality}"
          end
        else
          if @print
            puts "Warning, a repeated interaction was detected and omitted"
          end
          next
        end
        
      }
      if @interactions.length == 0
        @@unsuccesful_querries << self
      else
        @@all_querries[@id.to_sym] = self
        
      end
      
    else
      puts "the Web call failed - see STDERR for details..."
    end
  end
  
  
  def Intact_querry.get_querry(id)
    # returns the querry for the gene id
    return @@all_querries[id.to_sym]
  end
  
  
  def Intact_querry.get_all_querries
    return @@all_querries
  end
  
  
  def Intact_querry.get_failed_querries
    return @@unsuccesful_querries
  end
end