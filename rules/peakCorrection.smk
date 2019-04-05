rule cutAdapt:
	input:
		"data/peaks/peaks-{barcode}.txt"
	output:
		temp("data/peaks/input-peaks-{barcode}.txt")
	conda:
		"envs/On-rep-seq.yaml"
	shell:
		"""
		sed 1d {input} | while read line
		do
			P1=$(echo $line | cut -d',' -f 5)
			P2=$(echo $line | cut -d',' -f 6)
			name=$(echo $line | cut -d',' -f 3)
			cutadapt -m $P1 data/porechopped_2/{wildcards.barcode}.fastq -o data/peaks/{wildcards.barcode}_short_$name.fastq 
			cutadapt -M $P2 data/peaks/{wildcards.barcode}_short_$name.fastq -o data/peaks/{wildcards.barcode}_$name.fastq
			echo "{wildcards.barcode}_$name" >> {output}
			rm data/peaks/{wildcards.barcode}_short_$name.fastq
		done	
		"""

rule correctReads:
	input:
		"data/peaks/input-peaks-{barcode}.txt"
	output:
		temp("data/peaks/fixed_{barcode}.txt")
	params:
		"data/peaks"
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
		done
		"""
rule vSearch:
	input:
		"data/peaks/fixed_{barcode}.txt"	
	output:
		temp("data/peaks/vsearch_fixed_{barcode}.txt")
	params:
		"data/peaks"
	conda:
		"envs/On-rep-seq.yaml"
	shell:
		"""
		cat {input} | while read line
		do
			count=$(grep -c ">" {params}/$line.fa )
			min=$(echo "scale=0 ; $count / 5" | bc )
			echo $line
			vsearch --sortbylength {params}/$line.fa --output {params}/sorted_$line.fa
			vsearch --cluster_fast {params}/sorted_$line.fa -id 0.9  --consout {params}/consensus_$line.fasta -strand both -minsl 0.80 -sizeout -minuniquesize $min
			vsearch --sortbysize {params}/consensus_$line.fasta --output {params}/vsearch_$line.fa --minsize 50
			echo "vsearch_$line" >> {output}
			#remove all non wanted here
		done
		"""