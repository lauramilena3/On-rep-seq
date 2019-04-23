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
        "data/check.txt"

include: os.path.join(RULES_DIR, 'demultiplex.smk')
include: os.path.join(RULES_DIR, 'LCPs.smk')
include: os.path.join(RULES_DIR, 'peakCorrection.smk')
include: os.path.join(RULES_DIR, 'taxonomyAssignment.smk')
