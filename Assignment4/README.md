# Assignment 4 

## Sources:



## Bonus 1%:


#### Reciprocal-best-BLAST is only the first step in demonstrating that two genes are orthologous.  Write a few sentences describing how you would continue to analyze the putative orthologues you just discovered, to prove that they really are orthologues.


The reciprocal-best-blast is a high performing way to find putative orthologs, but not so great to resolve co-orthologies. I tried to overcome this problem with a method that not only takes the first best hit, but takes all hits that have an equal or lower e-value than the best hit, and a coverage above threshold (50%).

Still, we have the problem that these are only putative orthologs. In order to be more confortable saying these are indeed orthologs, we could take several approaches.

- We could try to anotate all the genes possible and compare the Gene Ontology (GO) annotated functions of the ortholog genes (we could do this with some code from assignment 2). This however is not the best way as orthology does not imply function conservation.

- Another possibility would be to build Clusters of Orthologs Groups (COGs) based on the sequence similarity network of the best-reciprocal-hits found.

- Finally, we could try to use the genes of n known species and assess the best reciprocal hits of the n species with the initial 2. If clusters are maintained, the original putative orthologs are indeed orthologs.

