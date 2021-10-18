require './Gene_class.rb'
require './Cross_class.rb'
require './SeedStock_class.rb'

class StockDatabase
  
  # This class is the entire Database, it contains every line from every file.
  # Each individual object can be accessed by get_gene(id), get_stock(id) and
  # get_cross(id). The database can both plant all seeds and compute the
  # chi-square test of all genes simoultaneously. 
  
  attr_accessor :Genes          # "attribute accessor" for "@Genes"
  attr_accessor :Cross          # "attribute accessor" for "@Cross"
  attr_accessor :SeedStock      # "attribute accessor" for "@SeedStock"
  attr_accessor :Gene_IDs       # "attribute accessor" for "@Gene_IDs"
  attr_accessor :Stock_IDs      # "attribute accessor" for "@Stock_IDs"
  attr_accessor :Parent1        # "attribute accessor" for "@Parent1"
  attr_accessor :Parent2        # "attribute accessor" for "@Parent2"

  
  def initialize(params={})
    
    # Description: Extracts data from the 3 tsv files and creates
    # the different Cross, Genes and SeedStock objects. 
    
    # First, three different object lists are created
    # with the information contained in the tables
    genes = read_gene_info(params.fetch(:gene_path))
    cross = read_cross_info(params.fetch(:cross_path))
    seedstock = read_seedstock_info(params.fetch(:seedstock_path))
    
    # In order to do fancy indexing, just the gene ids are extracted
    just_gene_ids = []
    genes.each { |gene| just_gene_ids << gene.Gene_ID }

    # In each seedstock object, the mutant gene id is replaced by its corresponding Gene object matching the gene id
    seedstock.each { |line|
      line.Mutant_Gene_ID = genes[ just_gene_ids.index(line.Mutant_Gene_ID) ]
      }
    
    # In order to do fancy indexing, just the stock ids are extracted   
    just_stock_ids = []
    seedstock.each { |stock| just_stock_ids << stock.Seed_stock }

    # In each cross object, the Parent1 and Parent2 are replaced
    # by their corresponding Stock objects matching the stock id    
    cross.each { |line|
      line.Parent1 = seedstock[ just_stock_ids.index(line.Parent1) ]
      line.Parent2 = seedstock[ just_stock_ids.index(line.Parent2) ]
      }
    
    # Different properties are saved as Class variables
    @Genes = genes
    @Cross = cross
    @SeedStock = seedstock
    @Genes_IDs = just_gene_ids
    @Stock_IDs = just_stock_ids
    
    @Parent1 = []
    @Parent2 = []
    cross.each { |line|
      @Parent1 << line.Parent1.Seed_stock
      @Parent2 << line.Parent2.Seed_stock }
    
  end
  
  
  def load_from_file(path)
    
    # Description: 'reads file in .tsv format and outputs data in a hash format'
    # Sources:
    # - https://linuxtut.com/how-to-handle-tsv-files-and-csv-files-in-ruby-b8798/
    # - https://albertogrespan.com/blog/csv-file-reading-in-ruby/
    require 'csv'
    data = CSV.read(path, { encoding: "UTF-8", headers: true, header_converters: :symbol,
                      converters: :all, col_sep: "\t"})
    # The header_converters: :symbol argument transforms the header 
    # into symbols to use those symbols for the keys of the hash.
    data = data.map { |d| d.to_hash }
    recordslist=[]
    data.each { |row| recordslist << row }
    return recordslist
  
  end


  def read_cross_info(cross_path)
    
    # The cross lines are loaded into the list records_list    
    records_list = load_from_file(cross_path)
    cross_list = []
    
    # The records list if filled with Cross objects created from the record lines
    records_list.each_with_index {|record|
      cross_list << Cross.new(parent1: record[:parent1],
                              parent2: record[:parent2],
                              f2_wild: record[:f2_wild],
                              f2_p1: record[:f2_p1],
                              f2_p2: record[:f2_p2],
                              f2_p1p2: record[:f2_p1p2])
      }
    return cross_list
  
  end
  
  
  def read_gene_info(gene_path)
    
    # The gene info lines are loaded into the list records_list
    records_list = load_from_file(gene_path)
    gene_list = []
    
    # The gene_list is filled with gene objects
    records_list.each {|record|
    gene_list << Gene.new(gene_id: record[:gene_id],
                          gene_name: record[:gene_name],
                          mutant_phenotype: record[:mutant_phenotype])
    }
    return gene_list
  
  end
    

  def read_seedstock_info(seedstock_path)
    
    # The seed stocks are loaded into the list records_list
    records_list = load_from_file(seedstock_path)
    seedstock_list=[]
    
    # The seed stock list is filled with SeedStock objects created with the records info
    records_list.each {|record|
    seedstock_list << SeedStock.new(seed_stock: record[:seed_stock],
                                    mutant_gene_id: record[:mutant_gene_id],
                                    last_planted: record[:last_planted],
                                    storage: record[:storage],
                                    grams_remaining: record[:grams_remaining])
    }
    return seedstock_list
  
  end


  def get_genes(id)
    
    if @Genes_IDs.include?(id)
      return @Genes[ @Genes_IDs.index(id) ]
    else
      puts "Warning! Gene " + id + " is not on the database, or something went wrong"
    end
    
  end


  def get_stock(id)
    
    if @Stock_IDs.include?(id)
      return @SeedStock[ @Stock_IDs.index(id) ]
    else
      puts "Warning! Stock " + id + " is not on the database, or something went wrong"
    end
    
  end


  def get_cross(id)
    
    crosses_of_id = []
    if @Parent1.include?(id)
      crosses_of_id << @Cross[ @Parent1.index(id) ]
    end
    if @Parent2.include?(id)
      crosses_of_id << @Cross[ @Parent2.index(id) ]
    end
    
    if crosses_of_id.length == 0
      puts "Warning! No crosses were found for stock id " + id
      return
    end
    
    return crosses_of_id
  
  end



    
  def plant(value)
    
    @SeedStock.each {|seed| seed.plant(value)}
    
  end
    
    
  def chi_square_test
    
    @Cross.each {|row|
      if row.chi_square != nil
        puts "Recording: "+row.Parent1.Mutant_Gene_ID.Gene_name+
        " is genetically linked to "+row.Parent2.Mutant_Gene_ID.Gene_name+
        " with chi-score = " + row.chi_square.to_s
        
      end
      
    }
      
  end
    
    
  def write_database(path)
    # Write to file in ruby: https://www.educba.com/ruby-write-to-file/
  
    header = "Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining"
    File.open(path, 'w') do |line|
      line.puts header
      @SeedStock.each {|row|
        line.puts row.Seed_stock + "\t" + row.Mutant_Gene_ID.Gene_ID + "\t" + row.Last_Planted +
        "\t" + row.Storage + "\t" + row.Grams_Remaining.to_s
      }
    end
  end
  
  
end
