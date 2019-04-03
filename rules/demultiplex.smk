rule demultiplexing_1:
    input:
        BASECALLED_DIR
    output:
        expand("data/porechopped_1/{barcode}.fastq", barcode=BARCODES)
    params:
        output_dir="data/porechopped_1/"
    conda:
        "envs/On-rep-seq.yaml"
    shell:
        """ 
        porechop -i {input} -b {params.output_dir} -t {threads} --discard_unassigned
        for barcode in {BARCODES}
        do
            touch {params.output_dir}/$barcode.fastq
        done
        """
rule demultiplexing_2:
    input:
        "data/porechopped_1/{barcode}.fastq" 
    output:
        "data/porechopped_2/{barcode}.fastq"
    conda:
        "envs/On-rep-seq.yaml"
    shell:
        """
        if [ -s {input} ];
        then
            porechop -i {input} -o {output} -t {threads} --fp2ndrun
        else
            touch {output}
        fi
        """