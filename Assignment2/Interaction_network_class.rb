require './Intact_querry_class.rb' 
require './Gene_class.rb' 


class Interaction_network
  
  # Class that holds the networks
  
  attr_accessor :genes           # "attribute accessor" for "@genes"
  attr_accessor :initial         # "attribute accessor" for "@initial"
  attr_accessor :annotations     # "attribute accessor" for "@annotations"
    
    
  def initialize(params={})
    genes = params.fetch(:genes) # genes must be a hash
    file = params.fetch(:file)
    @genes = find_a_network(genes, file) # all networks of initial genes
    @initial = initials
  end
   
  
  def try_to_combine_nets(report)
    unless @genes.length > 1
      puts "Already have only one network"
      return @genes
    end
    puts @genes.sort[@genes.length - 1].join ","
    temp_net = {}
    @genes.sort[@genes.length - 1].each { |gen|
      if temp_net.include? gen
        next
      end
      gen = Gene.get_gene(gen)
      temp_net[gen.id] = Interaction_network.all_levels_method(n=15,gen)
      }
    ewe = find_a_network(temp_net, report)
    if @genes.all? {|sub_net| sub_net.include? ewe}
      puts "ewe is in all networks"
    end
    
    @genes.each {|sub_net|
      ewe.each {|e|
        if e.is_a? Array
          puts "#{e}"
          e=e[0]
        end
        
        e = e.to_sym unless e.is_a? Symbol
        if sub_net.include? e
          puts "#{e.to_s} is in a network"
        end
        
        }
      }
  end
   
   
  def Interaction_network.only_initial_method(n,gene,temp=[],current=0)
    if current > n
      return temp
    end
    if gene.level == 0 and current == 0 # initial state, add the first gene
      temp |= [gene.id]
    end
    
    gene.partners.each {|partner|
      if Gene.get_gene(partner)
        partner = Gene.get_gene(partner)
      else
        puts "Warning, #{partner} is not a gene"
        next
      end
      
      if partner.level == 0
        #puts "Partner #{partner.id} is of level #{partner.level}"
        temp |= [partner.id]
      end
      temp |= Interaction_network.only_initial_method(n, partner, temp, current+1)
      }
    return temp
  end 
   
   
  def find_a_network(pseudo_interactions, nets = [], report)
    net = []
    
    pseudo_interactions.each { |initial|
      # initial[0] is the gene id and initial[1] its partners
      initial[1] = initial[1].each {|partner| partner = partner.to_sym} # we convert each partner to symbol
      gen_id = initial[0].to_sym
      partners = initial[1] 
      
      if net.empty? # Only for the first gene, add the genes to the network
        net |= [gen_id]
        net |= partners
        next
      end
      
      if net.include? gen_id and partners.all? { |partner| net.include? partner }
        # Network already contains every gene from this line.
        next
      end
      
      if partners.any? {|partner| net.include? partner} # If any of the partners are in the network, add the gene id and all partners
        net |= [gen_id]
        net |= partners
      elsif net.include? gen_id
        net |= [gen_id]
        net |= partners
      end
      
      unless net.include? gen_id # If the network doen't include the gene id, pass
        next
      end
    
      }
    net.each { |member| pseudo_interactions.delete(member) } # delete from the pseudo_interactions hash all entries processed.
    if net.length < 2 or net.count {|n| Gene.get_gene(n).level == 0} < 2
      #mal
    else
      nets |= [net] # add the net to the nets
      i = []
      net.each {|n|
        gene_n = Gene.get_gene(n)
        if gene_n.level == 0
          i |= [gene_n.id]
        end
        }
      report.puts "Network found: #{net.join ", "}"
      report.puts
      report.puts "Initial genes in the network: #{i.join ", "}"
      report.puts
    end
    
    if pseudo_interactions.empty?
      report.puts "All networks possible found"
      return nets
    end
    find_a_network(pseudo_interactions, nets, report)
  end
  
  
  def Interaction_network.all_levels_method(n,gene,temp=[],current=0)
    if current > n
      return temp
    end
    gene.partners.each {|partner|
      if Gene.get_gene(partner)
        partner = Gene.get_gene(partner)
      else
        #puts "Warning, #{partner} is not a gene"
        next
      end
      if temp.include? partner.id and partner.partners.all? { |p| temp.include? p }
        next
      end
      temp |= [partner.id]
      temp |= Interaction_network.all_levels_method(n, partner, temp, current+1)
      }
    return temp
  end
  
  
  def initials # function to create the initial genes attribute.
    initials = []
    @genes.each { |n|
      n.each {|g|
        gen = Gene.get_gene(g)
        if gen.level == 0
          initials |= [g]
        end
        }
      }
    return initials
    
  end
  
  
  def length # function to get the length(s) of the network(s)
    out = []
    @genes.each {|sub_net|
      out << sub_net.length
      }
    return out
  end
  
  
end