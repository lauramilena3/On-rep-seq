rule getFlowgrams:
	input:
		demultiplexed_2="demultiplex-step2/{barcode}.fastq"
	output:
		"LCPs/{barcode}.txt"
	shell:
		"""
		cat {input} | awk '{if(NR%4==2) print length($1)+0}' | sort -n | uniq -c | sed "s/   //g" |  sed "s/  //g" | sed "s/^ *//" > {output}
		"""

rule plotFlowgrams:
	input:
		flowgramsDir=directory("flowgrams")
	output:
		pdfResults="flowgrams/raw-seq-profiles.pdf"
	script:
		"/snakemake/plotFlowgrams.R"

rule detectPeaks:
	input:
		"flowgrams/{barcode}.txt"
	output:
		"peaks/peaks-${barcode}.txt"
	conda:
		"envs/R.yaml"
	shell:
	"""	 
	Rscript --vanilla peakpicker.R -f {input} -o {output} -v TRUE
	"""

rule createResultDirectories:
	input:
		peaks:"peaks/peaks-{barcode}.txt"
		demultiplexed_2="demultiplex-step2/{barcode}.fastq"
	output:
		barcodeDir=directory("{barcode}")
		failedDir=directory("failed_samples")
	shell:
	"""	 
	mv input.peaks {barcode}/peaks-{barcode}.txt
	mv input.demultiplexed_2 {barcode}/{barcode}.fastq
	mkdir failed_samples
	mv demultiplex-step2/*fastq failed_samples
	"""

rule cutAdapt:
	input:
		barcodeDir:directory("{barcode}")
	output:
		barcodeDir="{barcode}"
		failedDir=directory("failed_samples")
	shell:
	"""	 
	sed 1d *.txt | while read line
	do
	P1=$(echo $line | cut -d',' -f 5)
	P2=$(echo $line | cut -d',' -f 6)
	name=$(echo $line | cut -d',' -f 3)

	cutadapt -m ${P1}  *.fastq > short.fastq
	cutadapt -M ${P2}  short.fastq > input_peaks/${name}.fastq

	rm short.fastq
	done	
	"""