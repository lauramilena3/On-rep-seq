rule demultiplexing_1:
    input:
        BASECALLED_DIR
    output:
        temp(expand("data/01_porechopped_data/{barcode}_01.fastq", barcode=BARCODES))
    params:
        output_dir="data/01_porechopped_data"
    conda:
        "envs/On-rep-seq.yaml"
    threads: 16
    shell:
        """ 
        porechop -i {input} -b {params.output_dir} -t {threads} --discard_unassigned
        for barcode in {BARCODES}
        do
            touch {params.output_dir}/$barcode.fastq
            mv {params.output_dir}/$barcode.fastq {params.output_dir}/$barcode_01.fastq
        done
        """
rule demultiplexing_2:
    input:
        "data/01_porechopped_data/{barcode}_01.fastq" 
    output:
        "data/01_porechopped_data/{barcode}.fastq"
    conda:
        "envs/On-rep-seq.yaml"
    shell:
        """
        if [ -s {input} ];
        then
            porechop -i {input} -o {output} --fp2ndrun
        else
            touch {output}
        fi

        """