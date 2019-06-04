rule getLCPs:
	input:
		OUTPUT_DIR + "/01_porechopped_data/{barcode}.fastq"
	output:
		OUTPUT_DIR + "/02_LCPs/{barcode}.txt",
	params:
		OUTPUT_DIR + "/02_LCPs"
	shell:
		"""
		cat {input} | awk '{{if(NR%4==2) print length($1)+0}}' | sort -n | uniq -c | sed "s/   //g" |  sed "s/  //g" | sed "s/^ *// " > {output}
		"""
rule plotLCPs:
	input:
		expand(OUTPUT_DIR + "/02_LCPs/{barcode}.txt", barcode=BARCODES)
	output:
		pdfResults=OUTPUT_DIR + "/02_LCPs/LCP_plots.pdf"		
	run:
		#import libraries
		import matplotlib.pyplot as plt
		import numpy as np
		import math
		
		#set subplot features	
		filelist=sorted(input, key=lambda x: int(x.split('BC')[1].split(".")[0]))
		nro=math.ceil(len(filelist)/3)
		fig, axes = plt.subplots(nrows=nro, ncols=3, figsize=(12, 50), 
			sharex=True, sharey=True)
		plt.xlim(0,3500)

		#plot each barcode
		i = 0
		for row in axes:
			for ax in row:
				if i < len(filelist):
					if os.path.getsize(filelist[i]) > 10:
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
		fig.savefig(OUTPUT_DIR + "/02_LCPs/LCP_plots.pdf", bbox_inches='tight')

rule peakPicker:
	input:
		OUTPUT_DIR + "/02_LCPs/{barcode}.txt"
	output:
		txt=OUTPUT_DIR + "/03_LCPs_peaks/peaks_{barcode}.txt",
		pdf=temp(OUTPUT_DIR + "/03_LCPs_peaks/peaks_{barcode}.pdf")
	conda:
		"envs/R.yaml"
	shell:
		"""
		Rscript --vanilla scripts/peakpicker.R -f {input} -o {output.txt} -v TRUE || true 
		touch {output.txt}
		touch {output.pdf}
		"""
rule LCPsCluster:
	input:
		expand(OUTPUT_DIR + "/02_LCPs/{barcode}.txt", barcode=BARCODES)
	output:
		ipynb=OUTPUT_DIR + "/02_LCPs/LCP_clustering_heatmaps.ipynb",
		directory=(directory(OUTPUT_DIR + "/02_LCPs/LCPsClusteringData")),
		directory_data=(directory("r_saved_images")),
	params:
		ipynb="runnable_jupyter_on-rep-seq_flowgrams_clustering_heatmaps.ipynb",
		directory=OUTPUT_DIR + "/02_LCPs"
	conda:
		"envs/R.yaml"
	shell:
		"""
		mkdir -p {output.directory}
		cp {params.directory}/*.txt {output.directory}
		find {output.directory} -size -100c -delete
		Rscript -e "IRkernel::installspec()"
		./scripts/LCpCluster.R {output.directory} {params.ipynb}
		ln -sf {params.ipynb} {output.ipynb}
		#mv {output.directory_data}/runnable_jupyter_on-rep-seq_flowgrams_clustering_heatmaps* {output.directory}
		"""

