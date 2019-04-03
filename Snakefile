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
BASECALLED_DIR = 'data/basecalled/'
MULTIPLEXED = config["multiplexed"]
BARCODES = config["barcodes"].split()
SAMPLES,=glob_wildcards("data/basecalled/{sample}.fastq")

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