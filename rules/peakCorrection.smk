rule cutAdapt:
	input:
		"data/03_LCPs_peaks/peaks_{barcode}.txt"
	output:
		temp("data/03_LCPs_peaks/input-peaks-{barcode}.txt")
	conda:
		"envs/On-rep-seq.yaml"
	params:
		porechopped="data/01_porechopped_data",
		peaks="data/03_LCPs_peaks"
	shell:
		"""
		sed 1d {input} | while read line
		do
			P1=$(echo $line | cut -d',' -f 5 )
			P2=$(echo $line | cut -d',' -f 6)
			if [ $P2 > 300 ]
			then
				name=$(echo $line | cut -d',' -f 3)
				cutadapt -m $P1 {params.porechopped)/{wildcards.barcode}.fastq -o {params.peaks)/{wildcards.barcode}_short_$name.fastq 
				cutadapt -M $P2 {params.peaks)/{wildcards.barcode}_short_$name.fastq -o data/peaks/{wildcards.barcode}_$name.fastq
				echo "{wildcards.barcode}_$name" >> {output}
				rm data/peaks/{wildcards.barcode}_short_$name.fastq
			fi
		done	
		"""
rule correctReads:
	input:
		"data/03_LCPs_peaks/input-peaks-{barcode}.txt"
	output:
		temp("data/03_LCPs_peaks/fixed_{barcode}.txt")
	params:
		"data/03_LCPs_peaks"
	conda:
		"envs/canu.yaml"
	shell:
		"""
		cat {input} | while read line
		do
			echo $line
			./{config[canu_dir]}/canu -correct -p peak -d {params}/fixed_$line genomeSize=5k -nanopore-raw {params}/$line.fastq minReadLength=300 correctedErrorRate=0.01 corOutCoverage=5000 corMinCoverage=2 minOverlapLength=300 cnsErrorRate=0.1 cnsMaxCoverage=5000 useGrid=false || true
			if [ -s {params}/fixed_$line/peak.correctedReads.fasta.gz ];
        	then
        		gunzip -c {params}/fixed_$line/peak.correctedReads.fasta.gz > {params}/fixed_$line.fa
        		echo "fixed_$line" >> {output}
        	else
            	touch {output}
        	fi
        rm -rf {params}/fixed_$line
		done
		"""
rule vSearch:
	input:
		"data/03_LCPs_peaks/fixed_{barcode}.txt"	
	output:
		temp("data/03_LCPs_peaks/00_peak_consensus/vsearch_fixed_{barcode}.txt")
	params:
		LCPs="data/03_LCPs_peaks",
		consensus="data/03_LCPs_peaks/00_peak_consensus"
	conda:
		"envs/On-rep-seq.yaml"
	shell:
		"""
		cat {input} | while read line
		do
			count=$(grep -c ">" {params.LCPs}/$line.fa )
			min=$(echo "scale=0 ; $count / 5" | bc )
			echo "$line.fa" >> {output}
			vsearch --sortbylength {params.LCPs}/$line.fa --output {params.LCPs}/sorted_$line.fasta
			vsearch --cluster_fast {params.LCPs}/sorted_$line.fasta -id 0.9  --consout {params.LCPs}/consensus_$line.fasta -strand both -minsl 0.80 -sizeout -minuniquesize $min
			vsearch --sortbysize {params.LCPs}/consensus_$line.fasta --output {params.consensus}/$line.fa --minsize 50
			rm {params.LCPs}/sorted_$line.fa {params.LCPs}/consensus_$line.fasta
		done
		"""