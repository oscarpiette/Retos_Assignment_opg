require './StockDatabase_class.rb'
require './Gene_class.rb'
require './Cross_class.rb'
require './SeedStock_class.rb'


def main
  
  gene_arg = Regexp.new(/gene/)
  cross_arg = Regexp.new(/cross/)
  stock_arg = Regexp.new(/stock/)
  
  # Default plant value:
  to_plant = 7
  ARGV.each {|arg|
    if arg.to_i > 0
      to_plant = arg.to_i
    end
    }

  database = StockDatabase.new(gene_path: ARGV[ ARGV.index { |arg| gene_arg.match(arg)} ],
                  cross_path: ARGV[ ARGV.index { |arg| cross_arg.match(arg)} ],
                  seedstock_path: ARGV[ ARGV.index { |arg| stock_arg.match(arg)} ])

  database.plant(to_plant)
  database.chi_square_test
  database.write_database("./new_stock_file.tsv")
  
end

main