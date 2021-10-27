require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/main.rb' 
require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Interaction_class.rb' 
require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Gene_class.rb' 
require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Intact_querry_class.rb' 
require '/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Interaction_network_class.rb' 
require 'rest-client'  


# Control loop to check if all gene ids are arabidopsis gene identifiers.
genes_file = File.open('/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/ArabidopsisSubNetwork_GeneList.txt', 'r')
genes_lines = genes_file.readlines()
initial_genes = []
genes_lines.each {|line|
  unless arabidopsis_gene_id?(line.chomp)
     puts "Warning: id '#{line.chomp}' is not an arabidopsis gene identifier." 
  else
    initial_genes |= [line.chomp.downcase.capitalize] # we remove if any duplicated genes
  end }

### Prueba: =================================

#initial_genes = ["At4g17460", "At5g05690", "At2g46340"]

initial_genes.each {|id|
  Intact_querry.new({id: id, threshold: 0.45, print: false})
  }
puts "====================\nNumber of successful querries: #{Intact_querry.get_all_querries.length}"
puts "Number of unsuccesful querries: #{Intact_querry.get_failed_querries.length}"

puts "======================="
Intact_querry.get_all_querries.each {|fefe|
  fefe = fefe[1]
  puts "Partners of gene id '#{fefe.id}': \n"
  puts fefe.partners.join(", ")
  puts "-------"
  #Gene.new ({id: fefe.id, interactions: fefe.interactions, partners: fefe.partners})
  }



Int_file = File.open('/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Interactors_found_prueba.txt', 'w')
interacted_genes = []
# puts Intact_querry.get_all_querries
Intact_querry.get_all_querries.each {|line|
  line[1].partners.each {|p| Int_file.write p+"\n"
    interacted_genes << p}
  }
Int_file.close
puts "\nNumber of interacted genes: #{interacted_genes.length}\n\n"
# puts interacted_genes

Intact_querry.get_all_querries.each {|querry|
  Gene.new({id: querry[0],
             partners: querry[1].partners,
             interactions: querry[1].interactions,
             initial: true}) }
puts "Number of gene objects created: #{Gene.get_all_genes.length}"
puts "Gene objects created: #{Gene.get_all_genes.keys}"
# puts "Gene object At4g17460: #{Gene.get_gene("At4g17460").partners}"


interacted_genes.each {|interacted|
  Intact_querry.new({id: interacted, threshold: 0.45, print: false})}

puts "====================\nNumber of successful querries: #{Intact_querry.get_all_querries.length}"
puts "Number of unsuccesful querries: #{Intact_querry.get_failed_querries.length}"

interacted_genes2 = []
Intact_querry.get_all_querries.each {|line|
  line[1].partners.each {|p| 
    interacted_genes2 << p}
  }
puts "\nNumber of interacted genes: #{interacted_genes2.length}\n\n"

Intact_querry.get_all_querries.each {|querry|
  unless Gene.get_gene(querry[0])
    Gene.new({id: querry[0],
             partners: querry[1].partners,
             interactions: querry[1].interactions,
             initial: false})
  end
  
   }
puts "Number of gene objects created: #{Gene.get_all_genes.length}"
puts "Gene objects created: #{Gene.get_all_genes.keys}"

Gene.get_all_genes.each {|gen|
  gen[1].partners.each {|part|
    if Gene.get_all_genes.keys.include? part.to_sym
      part = Gene.get_gene(part)
      if part.initial
        puts "Creo que el gen #{gen[0]} interacciona con un gen inicial: #{part.id}"
        #puts gen[1].partners
      end

    end
    }
  }

# puts succesful_querries[1].inspect

#puts "======================="
#succesful_querries.each {|fefe|
#  puts "Partners of gene id '#{fefe.id}': \n"
#  puts fefe.partners.length
#  puts "-------"
#  #Gene.new ({id: fefe.id, interactions: fefe.interactions, partners: fefe.partners})
#  }
#puts Gene.get_all_genes.keys.length

#possible_interaction_partners = Intact_querry.get_querry("AT4g22890").partners
#possible_interaction_partners.each {|part|
#  puts Interaction_network.valid_interactions? ["AT4g22890", part]
#  }

#final_genes = []
#succesful_querries.each {|querry|
#  final_genes << querry.id
#  }
#



#puts Gene.get_gene("At4g17460").partners
#puts Gene.get_gene("At5g05690").partners
#puts Gene.get_all_genes.length
#puts "----------"
#puts "Network genes unique? : #{Gene.get_network_genes == Gene.get_network_genes.uniq}"
#puts "=============="
#puts "Network genes amongst the initial genes: \n#{
#  initial_genes.each {|g| if Gene.get_network_genes.include? g
#      puts g
#      end
#  }
#  }"

#puts "Number of genes in the network: #{Gene.get_network_genes.length}"
#puts "Number of interacions in the network: #{Gene.get_network_interactions.length}"

#puts "\n====================\n\n"

#initial_genes_d = initial_genes.map do |x|
#  x.downcase
#end

#Int_file = File.open('/home/osboxes/BioinformaticsIntroGit/Assignments/Assignment2/Interactors_found_prueba.txt', 'r')
#partner_genes = []
#Int_file.readlines.each {|gene|
#  gene = gene.chomp
#  unless arabidopsis_gene_id?(gene)
#    puts "Warning: id '#{gene}' is not an arabidopsis gene identifier." 
#  end
#  if initial_genes_d.include? gene.downcase
#    puts "Interacted gene #{gene} is among the initial genes"
#  end
#  partner_genes << gene
#  
#}

