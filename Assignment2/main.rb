require 'rest-client'  

# Create a function called "fetch" that we can re-use everywhere in our code

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


def get_locus_name(rest, print)
  
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

def arabidopsis_gene_id?(gene_id)
  arabidopsis_type = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
  unless arabidopsis_type.match(gene_id)
    puts "Warning! The Gene ID: '#{gene_id}' is not an arabidopsis gene identifier"
    puts "Arabidopsis gene identifiers have the format: /A[Tt]\d[Gg]\d\d\d\d\d/"
    return false
  else
    return true
  end
end
