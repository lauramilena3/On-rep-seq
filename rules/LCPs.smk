rule getLCPs:
	input:
		"data/porechopped_2/{barcode}.fastq"
	output:
		"data/LCPs/{barcode}.txt"
	shell:
		"""
		cat {input} | awk '{{if(NR%4==2) print length($1)+0}}' | sort -n | uniq -c | sed "s/   //g" |  sed "s/  //g" | sed "s/^ *// " > {output}
		"""
rule plotFlowgrams:
	input:
		expand("data/LCPs/{barcode}.txt", barcode=BARCODES)
	output:
		pdfResults="data/LCPs/LCPs.pdf"		
	run:
		#import libraries
		import matplotlib.pyplot as plt
		import numpy as np
		import math
		
		#set subplot features	
		filelist=sorted(input, key=lambda x: int(x.partition('BC')[2].partition('.')[0]))
		nro=math.ceil(len(filelist)/3)
		fig, axes = plt.subplots(nrows=nro, ncols=3, figsize=(12, 20), 
			sharex=True, sharey=True)
		
		#plot each barcode
		i = 0
		for row in axes:
			for ax in row:
				if i < len(filelist):
					if os.path.getsize(filelist[i]):
						data=np.loadtxt(filelist[i])
						X=data[:,0]
						Y=data[:,1]
					else:
						X=0
						Y=0

					ax.plot(Y, X)
					#add label to barcode subplot
					ax.text(0.9, 0.5, filelist[i].split("/")[-1].split(".")[0],
						transform=ax.transAxes, ha="right")
					
					i += 1
		#save figure to pdf				
		fig.savefig("data/LCPs/LCPs.pdf", bbox_inches='tight')

rule peakPicker:
	input:
		"data/LCPs/{barcode}.txt"
	output:
		"data/peaks/peaks-{barcode}.txt"
	conda:
		"envs/R.yaml"
	shell:
		"""
		Rscript --vanilla scripts/peakpicker.R -f {input} -o {output} -v TRUE
		touch {output}
		"""