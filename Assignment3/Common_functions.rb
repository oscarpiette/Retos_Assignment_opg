require 'bio'
require 'rest-client'

# Scans a given string for all the cttctt patterns, even if overlapping.
# Heavily inspired from: https://stackoverflow.com/questions/3520208/get-index-of-string-scan-results-in-ruby
#
# @note Positions are in biological format (start at 1.
# @param string [String] the string to look all the for cttctt.
# @return [Array] the list of start and end positions where a cttctt pattern is located.
# @example Get cttctt of sequence cttcttcttctt
#   match_cttctt("cttcttcttctt") #=> [[1, 6], [4, 9], [7, 12]]
def match_cttctt(string)
  cttctt = /(?=(cttctt))/
  positions = []
  string.scan(cttctt) do |cttctt_match|
    positions << [Regexp.last_match.offset(0).first + 1, Regexp.last_match.offset(0).first + 6]
  end
  return positions
end


# Function to check if a gene identifier is indeed an arabidopsis identifier.
#
# @param gene_id [String] the gene id to be tested.
# @return [Boolean] true if the identifier is an arabidopsis identifier.
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


# Function to write a line in the gff3 format for assignment 3. Information stored in the feature.
#
# @note Requires a Bio::Feature object to work.
# @param [String] gene the gene name or id.
# @param [Bio::Feature] feature the feature to write.
# @return [String]  the line in gff3 format.
def gff_line(gene, feature)
  pos = /(?<start>\d+)..(?<end>\d+)/.match feature.position
  qualifyers = feature.assoc
  return "#{gene}\t#{qualifyers['source']}\t#{feature.feature}\t#{pos['start']}\t#{pos['end']}\t#{qualifyers['score']}\t#{qualifyers['strand']}\t#{qualifyers['phase']}\t#{qualifyers['attributes']}"
end


# Function to retrieve gene information from the embl database.
#
# @note Requires the bio ruby gem to work.
# @param [Array] gene_list Array of genes to be retrieved from the embl database.
# @return [nil] if the embl website is not working propperly, or no gene has an entry in embl.
# @return [Hash] processed_genes Hash of Bio::EMBL objects if the website 
#   works and there is at least one gene from the list with information on embl.
def retrieve_gene_info(gene_list)
  require 'bio'
  processed_genes = {}
  gene_list.each {|gene|
    url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{gene}"
    result = fetch(url)
    unless result
      $stderr.puts "Oh no, no embl entry was retrieved from gene #{gene}"
      next
    end
    embl = Bio::EMBL.new(result.body)
    processed_genes[gene.to_sym] = embl unless embl.seq.empty?
  }
  if processed_genes.empty?
    $stderr.puts "Oh no, embl is not working now :("
    return
  end
  return processed_genes
end


# Function to retrieve the cctcct positions of a gene. Loops through all the exon features of the 
#   Bio::EMBL object and retrieves, if any, all the positions of the cttctt sequences.
#
# @param [String] id of the gene.
# @param [Bio::EMBL] emblgene Bio::EMBL object containing the embl-retrieved information about that gene.
# @param [Integer] chromosome_position defaults at 1, position of the gene relative
#   to the start of the chromosome.
# @return [nil] if no match was found in the exon feature.
# @return [Array] positions_of_gene if at least one match was found in the exon feature,
#   array containing all the positions of each cctcct. 
def retrieve_cttctt(id, emblgene, chromosome_position=1)
  cttctt = /cttctt/ # Regular expression for the cttctt sequence
  # puts "Processing gene #{id}..."
  positions_of_gene = []
  emblgene.features {|featur|
    next unless featur.feature == "exon" # skip if it is not an exon
    
    location = featur.locations.locations[0]
    temp_loc = featur.position
    begin
      seq = emblgene.naseq.splice(temp_loc)
    rescue
      # puts "\tERROR: #{location.xref_id} at #{temp_loc}"
      next
    end
    
    # puts "\tExon found at #{temp_loc}"
    if cttctt.match(seq)
      repeats = match_cttctt(seq)
      exon_loc = /(?<start>\d+)..(?<end>\d+)/.match(temp_loc)
      repeat_positions = []
      
      repeats.each {|repeat|
        if location.strand == 1
          start = exon_loc['start'].to_i + repeat[0] - 1 + chromosome_position - 1
          stop = exon_loc['start'].to_i + repeat[1] - 1 + chromosome_position - 1
          repeat_pos = "#{start}..#{stop}"
        elsif location.strand == -1
          start = exon_loc['end'].to_i - (repeat[1] - 1) + chromosome_position - 1
          stop = exon_loc['end'].to_i - (repeat[0] - 1) + chromosome_position - 1
          repeat_pos = "complement(#{start}..#{stop})"
        else
          $stderr.puts "Unknown strand: #{location.strand.to_s}"
          next
        end
        # puts "\tRepeat position at: #{repeat_pos}"
        repeat_positions |= [repeat_pos]
        }
      positions_of_gene |= repeat_positions
    end
    }
  #puts ""
  return positions_of_gene unless positions_of_gene.empty?
end


# Function to create all the Bio::Feature objects of the cttctt repeats of a given gene.
#
# @note I have named the cctcct repeat as turtwig_repeat, not for any particular reason.
# @note Requires the bio ruby gem to work.
# @param [Array] position array of positions of each cttctt found for a given gene.
# @return [Array] features_list array of new Bio::Feature objects of the cttctt repeats.
def annotate_features(position)
  features_list = []
  position.each {|pos|
    feat = Bio::Feature.new('turtwig_repeat', pos)
    feat.append(Bio::Feature::Qualifier.new('source', 'bioruby_finder'))
    feat.append(Bio::Feature::Qualifier.new('repeat_sequence', 'cttctt'))
    feat.append(Bio::Feature::Qualifier.new('score', '.'))
    feat.append(Bio::Feature::Qualifier.new('phase', '.'))
    feat.append(Bio::Feature::Qualifier.new('attributes', '.'))
    if /complement/.match pos
      feat.append(Bio::Feature::Qualifier.new('strand', '-'))
    else
      feat.append(Bio::Feature::Qualifier.new('strand', '+'))
    end
    features_list |= [feat]
    }
  return features_list
end


# Function to create the required gff file in 4a) and 5). 
#
# @note gff3 format: http://plants.ensembl.org/info/website/upload/gff3.html
# @param [String] filename desired filename for the file (.gff extension is automatically added).
# @param [Boolean] genomic option to work with local (4a) or genomic (5) coordinates.
# @param [Array] cttctt_genes array containing the names of genes with at least one cttctt repeat.
# @param [Hash] processed_genes hash of each gene and its Bio::EMBL object.
def create_gff(filename, genomic=false, cttctt_genes, features, processed_genes)
  gff_file = File.open("./#{filename}.gff", 'w')
  gff_file.puts "##gff-version 3"
  cttctt_genes.each {|gene|
    biosequence = processed_genes[gene].to_biosequence # converting embl to biosequence
    biosequence.features.concat( features[gene] ) # adding the features to the biosequence
    features[gene].each {|feat| # print output as gff
      if genomic
        gff_file.puts gff_line(biosequence.entry_id, feat) # biosequence.entry_id is the chromosome number.
      else
        gff_file.puts gff_line(gene, feat) 
      end
      }
    }
  gff_file.close
end

