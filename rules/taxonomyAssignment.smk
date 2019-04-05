rule taxonomyAssignment:
	input:
		"data/peaks/vsearch_fixed_{barcode}.txt"	
	output:
		"data/peaks/taxonomyFiles_{barcode}.txt"	
	params:
		"data/peaks"
	shell:
		"""
		cat {input} | while read line
		do
			kraken2 --db {config[kraken_db]} $line.fa --use-names > taxonomy_$line.txt
			echo "taxonomy_$line" >> {output}
		done
		"""

