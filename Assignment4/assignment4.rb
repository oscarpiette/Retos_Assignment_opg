# Pruebas
require_relative "./Common_functions.rb"
require 'bio'


### =================================================================
### 0. Preparing the script.
unless ARGV.length == 2
  $stderr.puts "Warning, this script gets the best reciprocal hits between only 2 databases, at least 3 arguments were given to this script."
  $stderr.puts "Try again provinding only 2 files"
  abort
end

# Options are fixed as follows
Filter = '"m S"'
E_value = 1e-6
Coverage = 0.5
First_only = true

# ARGV files provided:
files = ARGV
species_database = get_name_databases(files)
hash_files = Hash[species_database.zip(files)] # Hash = {db_name: db_path}
puts hash_files
puts
### ================================================
### 1. Making the databases
types_of_databases = {}
hash_files.each { |species, path|
  db_name, seq_type = create_blast_database(path, species)
  types_of_databases[db_name.to_sym] = seq_type
  }

puts "Types of sequences: #{types_of_databases}"
database_names = types_of_databases.keys

database1 = create_bio_blast(database_names[0], types_of_databases, E_value, Filter)
database2 = create_bio_blast(database_names[1], types_of_databases, E_value, Filter)
### ======================================================================
### 2. Query database 1 to blast database 2:
puts 
puts "Database 2, query 1:"

file1 = Bio::FlatFile.auto(files[0])
best_hits_query1_db2 = {}
file1.each_entry {|entry|
  results = blasting(entry, database2, E_value, Coverage, First_only)
  if results
    entry_name = entry.definition.split("|").first.rstrip
    best_hits_query1_db2[entry_name] = results
  end
  }
puts 
puts "------------- Best hits of querying database 1 into blast database 2 -------------"
puts best_hits_query1_db2
puts 

### ======================================================================================
### 3. Query database 2 into blast database 1:

puts 
puts "Database 1, query 2:"
puts

file2 = Bio::FlatFile.auto(files[1])
best_hits_query2_db1 = {}

file2.each_entry { |entry|
  next unless best_hits_query1_db2.values.any? {|value| value.any? {|hit| entry.definition.include? hit } }
  
  results = blasting(entry, database1, E_value, Coverage, First_only)
  if results
    entry_name = entry.definition.split("|").first.rstrip
    best_hits_query2_db1[entry_name] = results
  end
  }

puts "------------- Best hits of querying database 2 into blast database 1 -------------"
puts best_hits_query2_db1
puts


### =====================================================================================
### 4. Write report:
puts "Writing report..."

report = File.new("./report.tsv", "w")

report.puts "#Getting best reciprocal hits from 2 databases"
report.puts "#Parameters: filter option - #{Filter}, coverage threshold - #{Coverage}, E-value threshold - #{E_value}, First hit only? - #{First_only}"
report.puts "#Files:"
report.puts "##{hash_files.values.join("\t")}"
report.puts "#Database names:"
report.puts "##{hash_files.keys.join("\t")}"

# Get best reciprocal hits:
best_hits_query1_db2.each {|d1, d2|
  d2.each {|d2d2|
    next if best_hits_query2_db1[d2d2].nil? # The hit d2d2 is not in the database 1
    report.puts "#{d1}\t#{d2d2}" if best_hits_query2_db1[d2d2].include? d1
    }
  }
puts "done."