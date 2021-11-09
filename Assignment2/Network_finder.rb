require './common_functions.rb' 
require './Interaction_class.rb' 
require './Gene_class.rb' 
require './Intact_querry_class.rb' 
require './Interaction_network_class.rb'
require 'json'
require 'rest-client'  


report = File.open('./report.txt', 'w')
report.puts "Test: Are all gene ids arabidopsis gene identifiers?"
genes_file = File.open('./ArabidopsisSubNetwork_GeneList.txt', 'r')
initial_genes = []
genes_file.readlines().each {|line|
  unless arabidopsis_gene_id?(line.chomp)
     $stderr.puts "Warning: id '#{line.chomp}' is not an arabidopsis gene identifier."
     $stderr.puts "Stopping program"
     abort
  end
  initial_genes |= [line.chomp.downcase.capitalize] # we remove if any duplicated genes
  }
report.puts "Test passed."
###

interacts = search_interactions(searchs=2, genes = initial_genes, interacted={}, report)
interacted_genes, interacted_genes2 = interacts['i0'], interacts['i1']
report.puts
report.puts "Extracting fails."
fails = []
Intact_querry.get_failed_querries.each {|fail| fails |= [fail.id]}
report.puts "Creating L2 genes..."

interacted_genes2.each {|gene|
  if fails.include? gene
    next
  end
  unless Gene.get_gene(gene)
    partners = []
    Interaction.get_interactions(int1 = gene).each {|int|
      partners |= int.interactors
      }
    partners.delete gene # The gene cant interact with itself (not allowed in this program)
    unless partners.length <= 1
      Gene.new( {id: gene,
               level: 2,
               partners: partners,
               interactions: Interaction.get_interactions(int1=gene) })
    else
      fails |= [gene]
    end

  else # Gene object already exists
    next
  end
    }
report.puts "Final number of genes to analyse: #{Gene.get_all_genes.length}"
###
# removing fails in partners, this function was necessary but I think there may be a more elegant solution.


remove_fails(bad=fails)
report.puts
#report.puts "Level 2 genes with more than 1 partner: #{Gene.get_all_genes.values.count {|gen| gen.level == 2 and gen.partners.length > 1}}"
unless Gene.get_all_genes.values.count {|gen| gen.level == 2 and gen.partners.length <= 1} == 0
  $stderr.puts "Warning, some genes of level 2 are dead-ends"
end

i = Gene.get_all_genes.values.select {|gene| gene.level == 0}

l1, interacted_genes = interacted_list(interacted_genes)
l2, interacted_genes2 = interacted_list(interacted_genes2)

report.puts
report.puts "Number of initial genes: #{i.length}"
report.puts "Number of Level 1 genes: #{l1.length}"
report.puts "Number of Level 2 genes: #{l2.length}"
report.puts

transformed_i, transformed_l1, transformed_l2 = [], [], []
i.compact.each {|ei| transformed_i << ei.level}
l1.compact.each {|l| transformed_l1 << l.level}
l2.compact.each {|l| transformed_l2 << l.level}

report.puts "=============================="
report.puts "Summary of the genes extracted from the web:"
report.puts "0 <- Gene from the original 168 genes"
report.puts "1 <- Gene among the interactions of the initial genes"
report.puts "2 <- Gene among the interactions of interactions of initial genes"
report.puts
report.puts "Initial genes:"
report.puts transformed_i.join ""
report.puts
report.puts "Level 1 genes:"
report.puts transformed_l1.join ""
report.puts
report.puts "Level 2 genes:"
report.puts transformed_l2.join ""
report.puts

pseudo_network = {}
i.each { |gene|
  if pseudo_network.include? gene
    next
  end
  pseudo_network[gene.id] = Interaction_network.all_levels_method(n=2,gene)
  }

report.puts "----------------------------------------------------"
report.puts
networks = Interaction_network.new({genes: pseudo_network, file: report})
report.puts
report.puts "Length of the network(s): #{networks.length.join ", "}."


networks.genes.each {|sub_network|
  sub_network.each {|gen|
    gen = Gene.get_gene(gen)
    gen.annotate_go
    gen.annotate_kegg
    }
  }
report.puts

networks.genes.each {|sub_network|
  report.puts "==============================="
  report.puts "Sub network."
  report.puts
  report.puts "GO process:"
  list_of_gos, list_of_kegg = [], []
  sub_network.each {|gen|
    gen = Gene.get_gene(gen)
    list_of_gos |= [gen.annotations.annotations[:GO]]
    list_of_kegg |= [gen.annotations.annotations[:KEGG]]
    }
  report.puts list_of_gos
  report.puts
  report.puts "KEGG pathways"
  report.puts list_of_kegg
  }

puts "Report finished"




