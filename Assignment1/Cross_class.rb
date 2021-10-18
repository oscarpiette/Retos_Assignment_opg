class Cross
  
  attr_accessor :Parent1  # "attribute accessor" for "@Parent1"
  attr_accessor :Parent2  # "attribute accessor" for "@Parent2"
  attr_accessor :F2_Wild  # "attribute accessor" for "@F2_Wild"
  attr_accessor :F2_P1    # "attribute accessor" for "@F2_P1"
  attr_accessor :F2_P2    # "attribute accessor" for "@F2_P2"
  attr_accessor :F2_P1P2  # "attribute accessor" for "@F2_P1P2"

  def initialize(params={})
    @Parent1 = params.fetch(:parent1, "Unknown")
    @Parent2 = params.fetch(:parent2, "Unknown")
    @F2_Wild = params.fetch(:f2_wild, 0000)
    @F2_P1 = params.fetch(:f2_p1, 0000)
    @F2_P2 = params.fetch(:f2_p2, 0000)
    @F2_P1P2 = params.fetch(:f2_p1p2, 0000)
   
  end
  
  def chi_square
    # Chi square test: https://www.ncbi.nlm.nih.gov/books/NBK22084/
    #
    # Degrees of freedom of chi square: rows-1 * cols-1
    # (2 genes - 1) * (4 phenotype combinations -1) = 3
    #   https://towardsdatascience.com/chi-square-test-with-python-d8ba98117626
    #
    # Chi square table: https://www.ncbi.nlm.nih.gov/books/NBK21907/table/A675/?report=objectonly
    # A chi square > 7.815 is needed to prove with a p-value < 0.05 that the 2 genes are linked
    # sum((Observed - Expected)²/Expected) for each column
    # Expected = sum(all columns) * expected probability:
    # - 9/16 Wild <- wild phenotype AB
    # - 3/16 P1 and P2 <- phenotypes aB and Ab
    # - 1/16 P1P2 <- phenotype ab
    limit_chi_df_3 = 7.815
    total_n = self.F2_Wild + self.F2_P1 + self.F2_P2 + self.F2_P1P2
    expected = [total_n.to_f * 9/16, total_n.to_f * 3/16,
                total_n.to_f * 3/16, total_n.to_f * 1/16]
    
    result = [ ((self.F2_Wild - expected[0])**2)/expected[0],
                   ((self.F2_P1  - expected[1])**2)/expected[1],
                   ((self.F2_P2  - expected[2])**2)/expected[2],
                   ((self.F2_P1P2  - expected[3])**2)/expected[3] ]
    result = result.sum
    if result >= limit_chi_df_3
        return result
    else
      return nil
    end
    
  end
  
end
