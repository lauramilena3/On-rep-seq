rule taxonomyAssignment:
	input:
		"data/03_LCPs_peaks/00_peak_consensus/vsearch_fixed_{barcode}.txt"	
	output:
		temp("data/03_LCPs_peaks/taxonomyFiles_{barcode}.txt")
	params:
		consensus="data/03_LCPs_peaks/00_peak_consensus"
		taxonomy="data/03_LCPs_peaks/01_taxonomic_assignments"
	shell:
		"""
		cat {input} | while read line
		do
			if [ -s {params}/$line.fa ]
			then
				kraken2 --db {config[kraken_db]} {params.consensus}/$line.fa --use-names > {params.taxonomy}/taxonomy_$line.txt
				echo "taxonomy_$line" >> {output}
			else
				rm {params.consensus}/$line.fa
				touch {output}
			fi
		done
		"""
