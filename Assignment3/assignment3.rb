### TASK ==============================================================================================
### Your biologist collaborators are going to do a site-directed/insertional mutagenesis in Arabidopsis
### using the list of 167 genes from your last assignment as the desired targets.
### Inserts will be targeted to the repeat CTTCTT, and they want inserts to go into EXONS.

require 'bio'
require 'rest-client'
require './Common_functions.rb'

# Control to check if all genes are stil from Arabidopsis.
genes_file = File.open('./ArabidopsisSubNetwork_GeneList.txt', 'r')
initial_genes = []
genes_file.readlines().each {|line|
  unless arabidopsis_gene_id?(line.chomp)
     $stderr.puts "Warning: id '#{line.chomp}' is not an arabidopsis gene identifier."
     next
  end
  initial_genes |= [line.chomp.downcase.capitalize] # we remove if any duplicated genes
  }

## ===============================================================================================
## 1:  Using BioRuby, examine the sequences of the ~167 Arabidopsis genes from the last assignment
##     by retrieving them from whatever database you wish.
processed_genes = retrieve_gene_info(initial_genes)
puts "Total number of retrieved genes: #{processed_genes.length}"

## ====================================================================
## 2: Loop over every exon feature, and scan it for the CTTCTT sequence
has_ctt = {}
processed_genes.each {|id, emblgene| # id is the gene id and emblgene the embl gene object.
  has_ctt[id] = retrieve_cttctt(id, emblgene)
  }

# Removing any gene (if any) without cttcct.
has_ctt.each { |id, value|
  has_ctt.delete(id) if value.nil?
  }

puts "Genes that have cttctt sequence: #{has_ctt.keys.length}"
puts has_ctt.keys.join ", "

## ====================================================================================================
## 3:  Take the coordinates of every CTTCTT sequence and create a new Sequence Feature
## (you can name the feature type, and source type, whatever you wish
## the start and end coordinates are the first ‘C’ and the last ‘T’ of the match.).
## Add that new Feature to the EnsEMBL Sequence object.
## (YOU NEED TO KNOW: When you do regular expression matching in Ruby, use RegEx/MatchData objects
## there are methods that will tell you the starting and ending coordinates of the match in the string)

features = {}
has_ctt.each {|id, position|
  features[id] = annotate_features(position)
  }

# =================================================================================================
## 4a  Once you have found them all, and added them all, loop over each one of your CTTCTT features
## (using the #features method of the EnsEMBL Sequence object)
## and create a GFF3-formatted file of these features.

create_gff("features", genomic=false, has_ctt.keys, features, processed_genes)

## ======================================================================================================
## 4b  Output a report showing which (if any) genes on your list do NOT have exons with the CTTCTT repeat
report = File.open('./report.txt','w')
not_ctt = []
initial_genes.each {|initial|
  next if has_ctt.keys.include? initial.to_sym
  not_ctt << initial
  }
if not_ctt.length > 1
  report.puts "There are #{not_ctt.length} genes that don't have the cttctt sequence."
  report.puts "These genes are #{not_ctt.join ", "}"
elsif not_ctt.length == 1
  report.puts "Only gene #{not_ctt[0]} does not have the cttctt sequence."
else
  report.puts "There are no genes in the initial list without the cttctt Important repeat."
end
report.close


## PART 2 ======================================================================================================
## Biologists always want to “see the data”... and usually that means they want to see it
## in the context of all other genomic features.  ENSEMBL allows this.
## Unfortunately, “Coordinate systems” are a grano en el culo!
## The sequence files you retrieve (e.g. using dbfetch) indicates the feature start/stop
## relative to the small segment of DNA in that file.
## Online databases like ENSEMBL use whole-chromosome start/end coordinates (and sometimes contig coordinates).

## ===============================================================================
## 5:  Re-execute your GFF file creation so that the CTTCTT regions are now in the
## full chromosome coordinates used by EnsEMBL.  Save this as a separate file
## You have to calculate the chromosome coordinates yourself, somehow…
## hint - look in the information at the beginning of the sequence file.
## NOTE THAT THIS REQUIRES YOU TO CHANGE COLUMN 1 OF THE GFF FILE ALSO!
## NOT JUST THE START/END COORDINATES (see below)

puts "Getting chromosome positions..."
chromosome_positions = {}
processed_genes.each {|gene, object|
  biosequence = object.to_biosequence
  *uninteresting, chromosome, start, stop, always1 = biosequence.primary_accession.split ':'
  uninteresting = [uninteresting, always1] # just to make komodo debugger happy
  puts "Gene #{gene} starts at #{start}, stops at #{stop}, located in chromosome #{chromosome}"
  puts "It is not always 1" unless always1.to_i == 1
  chromosome_positions[gene] = start # We only record the start position
  }
puts "Chromosome positions:"
puts chromosome_positions
puts

# Re-getting cttctt positions but now in genomic context.
has_ctt2 = {}
processed_genes.each {|id, emblgene| # id is the key and emblgene the embl gene object.
  has_ctt2[id] = retrieve_cttctt(id, emblgene, chromosome_position = chromosome_positions[id].to_i)
  }
has_ctt2.each {|id, value|
  has_ctt2.delete(id) if value.nil?
  }

$stderr.puts "Something went wrong... Probably embl went down during the execution of this script" unless has_ctt.keys == has_ctt2.keys

features = {}
has_ctt2.each {|id, position|
  features[id] = annotate_features(position)
  }

create_gff("features2", genomic=true, has_ctt2.keys, features, processed_genes)


### SOURCES: ----------------------------------------------------------------------
# http://plants.ensembl.org/info/website/upload/index.html