import os
import re

#======================================================
# Config files
#======================================================
configfile: "config.yaml"

#======================================================
# Global variables
#======================================================
RULES_DIR = 'rules'
BASECALLED_DIR = config["basecalled_dir"]
BARCODES = config["barcodes"].split()
#======================================================
# Rules
#======================================================
 
rule all:
    input:
        "data/02_LCPs/LCP_plots.pdf",
        "data/02_LCPs/LCP_clustering_heatmaps.html",
        expand("data/03_LCPs_peaks/taxonomyFiles_{barcode}.txt", barcode=BARCODES)
       # expand("data/03_LCPs_peaks/input-peaks-{barcode}.txt", barcode=BARCODES)

include: os.path.join(RULES_DIR, 'demultiplex.smk')
include: os.path.join(RULES_DIR, 'LCPs.smk')
include: os.path.join(RULES_DIR, 'peakCorrection.smk')
include: os.path.join(RULES_DIR, 'taxonomyAssignment.smk')
