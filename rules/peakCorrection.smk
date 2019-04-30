rule cutAdapt:
	input:
		OUTPUT_DIR + "/03_LCPs_peaks/peaks_{barcode}.txt"
	output:
		temp(OUTPUT_DIR + "/03_LCPs_peaks/input-peaks-{barcode}.txt")
	conda:
		"envs/On-rep-seq.yaml"
	params:
		porechopped=OUTPUT_DIR + "/01_porechopped_data",
		peaks=OUTPUT_DIR + "/03_LCPs_peaks"
	shell:
		"""
		sed 1d {input} | while read line
		do
			P1=$(echo $line | cut -d',' -f 5 )
			P2=$(echo $line | cut -d',' -f 6)
			if [ $P2 > 300 ]
			then
				name=$(echo $line | cut -d',' -f 3)
				cutadapt -m $P1 {params.porechopped}/{wildcards.barcode}.fastq -o {params.peaks}/{wildcards.barcode}_short_$name.fastq 
				cutadapt -M $P2 {params.peaks}/{wildcards.barcode}_short_$name.fastq -o {params.peaks}/{wildcards.barcode}_$name.fastq
				echo "{wildcards.barcode}_$name" >> {output}
				rm {params.peaks}/{wildcards.barcode}_short_$name.fastq
			fi
		done
		touch {output}
		"""
rule correctReads:
	input:
		OUTPUT_DIR + "/03_LCPs_peaks/input-peaks-{barcode}.txt"
	output:
		temp(OUTPUT_DIR + "/03_LCPs_peaks/fixed_{barcode}.txt")
	params:
		OUTPUT_DIR + "/03_LCPs_peaks"
	conda:
		"envs/canu.yaml"
	shell:
		"""
		cat {input} | while read line
		do
			echo $line
			./{config[canu_dir]}/canu -correct -p peak -d {params}/fixed_$line genomeSize=5k -nanopore-raw {params}/$line.fastq \
			minReadLength=300 correctedErrorRate=0.01 corOutCoverage=5000 corMinCoverage=2 minOverlapLength=300 cnsErrorRate=0.1 \
			cnsMaxCoverage=5000 useGrid=false || true
			if [ -s {params}/fixed_$line/peak.correctedReads.fasta.gz ];
        	then
        		gunzip -c {params}/fixed_$line/peak.correctedReads.fasta.gz > {params}/fixed_$line.fastq
        		echo "fixed_$line" >> {output}
        	fi
        	rm -rf {params}/fixed_$line
        	rm {params}/$line.fastq
		done
		touch {output}
		"""
rule vSearch:
	input:
		OUTPUT_DIR + "/03_LCPs_peaks/fixed_{barcode}.txt"	
	output:
		temp(OUTPUT_DIR + "/03_LCPs_peaks/00_peak_consensus/vsearch_fixed_{barcode}.txt")
	params:
		LCPs=OUTPUT_DIR + "/03_LCPs_peaks",
		consensus=OUTPUT_DIR + "/03_LCPs_peaks/00_peak_consensus"
	conda:
		"envs/On-rep-seq.yaml"
	shell:
		"""
		cat {input} | while read line
		do
			count=$(grep -c ">" {params.LCPs}/$line.fastq )
			min=$(echo "scale=0 ; $count / 5" | bc )
			echo "$line" >> {output}
			vsearch --sortbylength {params.LCPs}/$line.fastq --output {params.LCPs}/sorted_$line.fasta
			vsearch --cluster_fast {params.LCPs}/sorted_$line.fasta -id 0.9  --consout {params.LCPs}/consensus_$line.fasta -strand both -minsl 0.80 -sizeout -minuniquesize $min
			vsearch --sortbysize {params.LCPs}/consensus_$line.fasta --output {params.consensus}/$line.fasta --minsize 50
			rm {params.LCPs}/sorted_$line.fasta {params.LCPs}/consensus_$line.fasta {params.LCPs}/$line.fastq
		done
		touch {output}
		"""