require './common_functions.rb'
require './Interaction_class.rb'
require './Gene_class.rb' 


class Intact_querry
  
  # Class to compute the querry to the intact server and retrieve all information
  
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
    id = params.fetch(:id)
    @id = id.downcase.capitalize
    @url = @@adress + @id + @@format
    res = fetch(@url)
    @@threshold = params.fetch(:threshold, 0.45)
    @interactions = []
    @partners = []
    @print = params.fetch(:print, true)

    if res  
      body = res.body
      if @print
        puts "====================="
        puts "Interaction querry of gene id #{@id}:"
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
          interactorA, interactorB = interactorA.downcase.capitalize, interactorB.downcase.capitalize
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
    return @@all_querries[id.to_sym]
  end
  
  
  def Intact_querry.get_all_querries
    return @@all_querries
  end
  
  
  def Intact_querry.get_failed_querries
    return @@unsuccesful_querries
  end
  
  
  def remove_failed(fails)
    # Partners before:
    pb = @partners
    # Interactions before:
    ib = @interactions
    
    fails.each {|fail|
      @partners.delete(fail)
      @interactions.each {|int|
        if int.include? fail
          @interactions.delete(int)
        end
        
        }
      }
    unless pb == @partners or ib == @interactions
      puts "Partners before: #{pb.join ","}"
      puts "interactions after: #{ib.join ","}"
      puts "Partners after: #{@partners.join ","}"
      puts "interactions after: #{@interactions.join ","}"
    end
    
    
  end
  
  
  def get_locus_name(rest, print) # function to get the arabidopsis ids from the querry
  
    # match data: https://ruby-doc.org/core-3.0.2/MatchData.html
    # columns 5 and 6 are the aliases of interactors A and B, where the arabidopsis id is located.
    # We can do this because the tab25 is strict, and all columns are mandatory
    interactorA = rest[4].split("|") 
    interactorB = rest[5].split("|")
    interactorA = get_arabidopsis_id(interactorA)[0]
    interactorB = get_arabidopsis_id(interactorB)[0]
  
    if interactorA.nil?
      if print
        puts "Warning, the interaction partner does not have an arabidopsis gene identifier!"
        #$Stderr.puts "Warning, the interaction partner does not have an arabidopsis gene identifier!"
      end
  
    end
    
    return interactorA, interactorB
  
  end


  def get_arabidopsis_id(aliases)
    # get all arabidopsis ids
    out_list = []
    ara_id = /A[Tt]\d[Gg]\d\d\d\d\d/
    aliases.each {|element|
      if ara_id.match(element)
        match = ara_id.match(element)[0]
        out_list |= [match]
      end
      }
    return out_list
  
  end
  
  
end