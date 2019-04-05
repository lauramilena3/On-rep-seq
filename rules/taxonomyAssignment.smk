rule taxonomyAssignment:
	input:
		"data/peaks/vsearch_fixed_{barcode}.txt"	
	output:
		temp("data/taxonomyFiles_{barcode}.txt")
	params:
		"data/taxonomy_assignments"
	shell:
		"""
		cat {input} | while read line
		do
			kraken2 --db {config[kraken_db]} $line.fa --use-names > {params}/taxonomy_$line.txt
			echo "taxonomy_$line" >> {output}
		done
		"""
