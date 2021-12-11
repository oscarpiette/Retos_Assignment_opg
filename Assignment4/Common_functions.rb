require 'bio'
require 'rest-client'


# Function to create a blast database with the command makeblastdb.
#
# @note This function shuts down the program if it fails to recognize the type of database.
#   It also relies on the first entry in the file to detect the type of the whole database.
# @param [String] path_to_file path of the file containing the database.
# @param [String] name Species name if retrieved succesfully, else the same as path_to_file.
# @return [String] name same as input
# @return [String] type Detected type of the database. Either 'nucl' for a nucleotide sequence database,
#   or 'prot' for a protein sequence database.
def create_blast_database(path_to_file, name)
  *rest, final = path_to_file.split "\/" # split the path by "/" to get the name of the file.
  rest = rest # komodo debugger quiet
  puts "Making Database of file: #{final}"
  
  flatfile = Bio::FlatFile.auto(path_to_file)
  begin
    seq = flatfile.next_entry().aaseq()
  rescue
    seq = flatfile.next_entry().naseq()
  rescue # Undetected error
    $stderr.puts "Detected sequence type was neither aminoacid nor nucleotide"
    abort
  end
  
  file_type = Bio::Sequence.auto(seq).moltype
  type = 'nucl' if file_type == Bio::Sequence::NA
  type = 'prot' if file_type == Bio::Sequence::AA
  unless type
    $stderr.puts "Error, unrecognized database type #{file_type}. Shutting down program"
    abort
  end
  puts `makeblastdb -in #{path_to_file} -dbtype #{type} -out #{name}` # to the system
  return name, type
end


# Function to blast an entry to a specified database and get the best hit(s).
#
# @note Although we want only the first hit, I also included an option 
#   (first_only = false) to keep multiple hits as there may be more than 1 ortholog.
# @param [Bio::FastaFormat] entry Entry to be queried.
# @param [Bio::Blast] database Database in which to look for potential orthologs.
# @param [Float] e_value E-value to be used in the options as a filter.
# @param [Float] coverage Coverage threshold to be used in the options as a filter.
# @param [Boolean] first_only switch to activate or deactivate the first-only method.
# @return [Boolean] false if no hits are found
# @return [Array] Array of the name(s) of the best hit(s).
def blasting(entry, database, e_value, coverage, first_only=false)
  #puts "."
  query_results = database.query(entry)
  unless query_results.hits.any? {|hit| hit.evalue < e_value}
    return false
  end
  #puts "Query length: #{query_results.query_len}"
  #puts "entry: #{entry.definition}"
  first_best_hit = query_results.hits.first
  if first_only
    query_coverage = (first_best_hit.query_end.to_i - first_best_hit.query_start.to_i)/first_best_hit.query_len.to_f
    if query_coverage > coverage
      return [first_best_hit.definition.split("|").first.rstrip]
    else
      return false
    end
  end
  best_hits = []
  query_results.hits.each {|hit|
    best_hits << hit if hit.evalue <= first_best_hit.evalue
    }
  
  best_hits.each {|hit|
    query_coverage = (hit.query_end.to_i - hit.query_start.to_i)/hit.query_len.to_f
    best_hits.delete(hit) unless query_coverage > coverage
    }
  
  if best_hits.length == 0
    return false
  end
  
  best_hit_names = []
  best_hits.each {|hit|
    best_hit_names << hit.definition.split("|").first.rstrip
    }
  return best_hit_names
  
end



# Function to access the web, and handle possible exceptions when doing so.
#
# @note Function donated by Mark Wilkinson.
# @note Requires the rest-client ruby gem.
# @author Mark_Wilkinson.
# @param [String] url the URL of the page to download.
# @param [Hash] headers the headers of the web call if needed.
# @param [String] user the username if so requires the web call.
# @param [String] pass the password if so requires the web call.
# @return [Boolean] false if the web call failed.
# @return [RestClient::Response] response from the web call if it succeded.
def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
  require 'rest-client'
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
    return response
  rescue RestClient::Exception => e
    $stderr.puts e.inspect
    response = false
    return response
  rescue Exception => e
    $stderr.puts e.inspect
    response = false
    return response 
end


# Function to detect the type of Bio::Blast object to create.
#
# @note In this assignment, only 2 types of database are used, but all 4 types are supported.
# @note tblasn: protein sequence query is compared to nucleotide database.
#   blastp: protein sequence query is compared to protein database.
#   blastn: nucleotide sequence query is compared to nucleotide database.
#   blastx: nucleotide sequence query is translated in six reading frames compared o those in a protein sequence database. 
# @param [Sring] name name of the database to build a Bio::Blast.
# @param [Hash] hash_db_type Hash containing the names and type of db of both databases.
# @return [nil] if more than 2 databases were provided,
# @return [nil] if both databases have the same name,
# @return [nil] if the type of database to be built does not match any of the 4 described above.
# @return [String] type of the database to be built as a Bio::Blast object
def detect_blast_type(name, hash_db_type)
  unless hash_db_type.length == 2
    $stderr.puts "Warning, only pairwise blast databases are supported"
    return
  end
  type_of_database = hash_db_type[name]
  type_of_query = ""
  hash_db_type.keys.each {|key|
    unless key == name
      type_of_query = hash_db_type[key] 
    end
    }
  return if type_of_query.empty? # This will happen if both databases have the same name
  
  return "tblastn" if type_of_database == "nucl" && type_of_query == "prot"
  return "blastp" if type_of_database == "prot" && type_of_query == "prot"
  return "blastn" if type_of_database == "nucl" && type_of_query == "nucl"
  return "blastx" if type_of_database == "prot" && type_of_query == "nucl"
  $stderr.puts "Warning, unsupported blast type of database"
  return
end


# Function to try to get the species name of both databases
#
# @note Uses the embl server to fetch the result from the web.
#   It relies on the first entry to determine the species of the whole database.
#   Thus, it is not applicable to metagenomic files or mixed species files.
# @param [Array] files Array of paths leading to the 2 databases.
# @return [Array] array of names of the databases. Either containing species or the file paths.
def get_name_databases(files)
  database_names = []
  files.each {|file|
    flat_file = Bio::FlatFile.auto(file)
    gene_id = flat_file.next_entry.entry_id
    url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{gene_id}"
    result = fetch(url)
    unless result
      database_names << file
      next
    end
    embl = Bio::EMBL.new(result.body)
    begin
      species = embl.species
      species.gsub!(/[^\w]/, "_")  # to avoid further errors, any non-word character is converted to "_"
    rescue
      species = file
    end
    database_names << species
    }
  database_names.uniq!
  return files unless database_names.length == files.length
  return database_names

end


# Function to create a Bio::Blast object
#
# @note Requires the bio ruby gem to work.
# @param [String] name Name of the database.
# @param [Hash] type_hash Hash containing the database names as keys and the database types as values.
# @param [Float] eval E-value to be used as an option.
# @param [String] filter Filter to be used as an option.
# @return [Bio::Blast] the bio::blast object.
def create_bio_blast(name, type_hash, eval, filter)
  require 'bio'
  db_type = detect_blast_type(name, type_hash)
  return Bio::Blast.new(program = db_type, name.to_s, opt = "-e #{eval} -F #{filter}", server = 'local')
end