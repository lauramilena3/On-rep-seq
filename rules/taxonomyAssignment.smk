rule taxonomyAssignment:
	input:
		OUTPUT_DIR + "/03_LCPs_peaks/00_peak_consensus/vsearch_fixed_{barcode}.txt"	
	output:
		merged=temp(OUTPUT_DIR + "/03_LCPs_peaks/merged_fixed_{barcode}.fasta"),
		taxonomy=OUTPUT_DIR + "/03_LCPs_peaks/01_taxonomic_assignments/taxonomy_{barcode}.txt"
	params:
		consensus=OUTPUT_DIR + "/03_LCPs_peaks/00_peak_consensus"
	shell:
		"""
		mkdir -p {params.taxonomy}
		cat {input} | while read line
		do
			echo "{params.consensus}/$line.fasta"
			if [ -s {params.consensus}/$line.fasta ]
			then
				cat {params.consensus}/$line.fasta >> {output.merged}
			fi
		done
		kraken2 --db {config[kraken_db]} {output.merged} --use-names > {output.taxonomy}
		touch {output.taxonomy}
		"""
rule checkOutputs:
	input:
		expand(OUTPUT_DIR + "/03_LCPs_peaks/01_taxonomic_assignments/taxonomy_{barcode}.txt", barcode=BARCODES),
	output:
		protected(OUTPUT_DIR + "/check.txt")
	shell:
		"""
		echo "On-rep-seq succesfuly executed" >> {output}
		"""

