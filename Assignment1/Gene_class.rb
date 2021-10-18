class Gene
  
  attr_accessor :Gene_ID           # "attribute accessor" (read and write) for "Gene_ID"
  attr_accessor :Gene_name         # "attribute accessor" (read and write) for "@Gene_name"
  attr_accessor :mutant_phenotype  # "attribute accessor" (read and write) for "@mutant_phenotype"
  
  def initialize(params={})
    gene_id = params.fetch(:gene_id, "Unknown")
    @Gene_name = params.fetch(:gene_name, "Unknown")
    @mutant_phenotype = params.fetch(:mutant_phenotype, "Unknown")
    @Gene_ID = validate_gene_id(gene_id)
  end
  
  def validate_gene_id(gene_id)
    arabidopsis_type = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
    unless arabidopsis_type.match(gene_id)
      puts "Warning! The Gene ID: '" + gene_id + "' is not an arabidopsis gene identifier"
      puts "Arabidopsis gene identifiers have the format: /A[Tt]\d[Gg]\d\d\d\d\d/"
      return nil
    else
      return gene_id
    end
  end
  
end

# ==========================
## TEST GENE IDs:
#unless Gene.new({gene_id: "AT9g12345"}).Gene_ID == "AT9g12345"
#    puts "Something went wrong"
#end
#
#unless Gene.new({gene_id: "11111111"}).Gene_ID == nil
#    puts "Something went wrong"
#end
#
#unless Gene.new({gene_id: "i"}).Gene_ID == nil
#  puts "Something went wrong"
#end

