rule taxonomyAssignment:
	input:
		"data/peaks/vsearch_fixed_{barcode}.txt"	
	output:
		temp("data/peaks/taxonomyFiles_{barcode}.txt")
	params:
		"data/peaks"
	shell:
		"""
		cat {input} | while read line
		do
			if [ -s {params}/$line.fa ];
			then
				kraken2 --db {config[kraken_db]} {params}/$line.fa --use-names > {params}/taxonomy_$line.txt
				echo "taxonomy_$line" >> {output}
			else
				touch {output}
			fi
		done
		"""
