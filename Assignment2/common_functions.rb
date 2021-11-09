require 'rest-client'  

# Create a function called "fetch" that we can re-use everywhere in our code
# fetch function was donated by Mark Wilkinson

def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
  response = RestClient::Request.execute({
    method: :get,
    url: url.to_s,
    user: user,
    password: pass,
    headers: headers})
  return response
  
  rescue RestClient::ExceptionWithResponse => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue RestClient::Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
end


def arabidopsis_gene_id?(gene_id) # function to check if it is indeed a arabidopsis identifier
  arabidopsis_type = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
  unless arabidopsis_type.match(gene_id)
    puts "Warning! The Gene ID: '#{gene_id}' is not an arabidopsis gene identifier"
    puts "Arabidopsis gene identifiers have the format: /A[Tt]\d[Gg]\d\d\d\d\d/"
    return false
  else
    return true
  end
end


def interacted_list(interacted)
  list = []
  interacted.each {|int|
    unless Gene.get_gene(int)
      interacted.delete(int)
      next
    end
    int = Gene.get_gene(int)
    list << int
    }
  if list.all? { |element| element.is_a? Gene}
    return list, interacted
  else
    $stderr.puts "Warning! Not all elements of the list are genes"
    return list, interacted
  end
  
end


def search_interactions(searchs=2, current=1, genes, interacted, report)
  if current > searchs
    return interacted
  end
  ###
  report.puts "Querrying level #{current-1} genes..."
  genes.each {|id| Intact_querry.new( {id: id, threshold: 0.45, print: false} ) }
  report.puts "Number of successful querries: #{Intact_querry.get_all_querries.length}"
  report.puts "Number of unsuccesful querries: #{Intact_querry.get_failed_querries.length}"
  report.puts
  report.puts "Compiling failed querries and refining succesfull querries..."
  fails = []
  Intact_querry.get_failed_querries.each {|fail| fails |= [fail.id]}
  Intact_querry.get_all_querries.values.each { |querry| querry.remove_failed(fails) }
  report.puts "Registering interacted genes (level #{current} genes)"
  interacted_genes = []
  Intact_querry.get_all_querries.values.each {|line|
    line.partners.each { |p|
      interacted_genes << p}
    }
  ###
  report.puts
  report.puts "Removing from the interacted genes (if any) all genes with failed querries"
  Intact_querry.get_failed_querries.each {|fail|
    if interacted_genes.include? fail.id
      puts "Warning! The interacted gene #{fail.id} failed its querry, removing this gene from the interacted gene list"
      interacted_genes.delete fail.id
    end
    }
  report.puts "Number of interacted genes: #{interacted_genes.length}\n\n"
  report.puts
  report.puts "Creating gene objects (Level #{current - 1})..."
  Intact_querry.get_all_querries.each { |querry|
    unless Gene.get_gene(querry[0])
      Gene.new({id: querry[0],
               partners: querry[1].partners,
               interactions: querry[1].interactions,
               level: current - 1})
    end
     }
  ###
  interacted["i" + (current-1).to_s] = interacted_genes
  search_interactions(searchs, current=current+1, genes = interacted_genes, interacted, report)
end


def remove_fails(bad)
  count_of_failed = 0
  Gene.get_all_genes.values.each {|gen|
    gen.partners.each {|p|
      if bad.include? p
        gen.partners.delete(p)
        count_of_failed +=1
      end
    }
  }
  if count_of_failed > 0
    remove_fails(bad)
  end
end
