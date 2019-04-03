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
        "data/LCPs/LCPs.pdf",
        expand("data/peaks/vsearch_fixed_{barcode}.txt", barcode=BARCODES)

include: os.path.join(RULES_DIR, 'demultiplex.smk')
include: os.path.join(RULES_DIR, 'LCPs.smk')
include: os.path.join(RULES_DIR, 'peakCorrection.smk')
include: os.path.join(RULES_DIR, 'taxonomyAssignment.smk')
