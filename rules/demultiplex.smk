rule demultiplexing_1:
    input:
        BASECALLED_DIR
    output:
        temp((OUTPUT_DIR + "/01_porechopped_data/{{sample}}/{barcode}.fastq", barcode=wildcards.barcode))
    params:
        output_dir=OUTPUT_DIR + "/01_porechopped_data/{{sample}}"
    conda:
        "envs/On-rep-seq.yaml"
    message:
        "Demultiplexing step 1"
    threads: 2
    shell:
        """
        porechop -i {wildcard.sample}.fastq -b {params} -t {threads} --discard_unassigned --verbosity 2 > /dev/null 2>&1
        line=$(echo {BARCODES})
        for barcode in $line
        do
            touch {params}/$barcode.fastq
        done
        """

rule merge_first_demultiplexing:
    input:
        expand(OUTPUT_DIR + "/01_porechopped_data/{sample}/{{barcode}}.fastq", sample=SAMPLES)
    output:
        temp(OUTPUT_DIR + "/01_porechopped_data/{barcode}.fastq")
    message:
        "Merging barcodes"
    threads: 2
    shell:
        """
        cat {input} > {output}
        """

rule demultiplexing_2:
    input:
        OUTPUT_DIR + "/01_porechopped_data/{barcode}.fastq"
    output:
        OUTPUT_DIR + "/01_porechopped_data/{barcode}_demultiplexed.fastq"
    conda:
        "envs/On-rep-seq.yaml"
    shell:
        """
        if [ -s {input} ]
        then
            porechop -i {input} -o {output} --fp2ndrun
            reads=$(grep -c "^@" {output})
            if (( {{$reads}} < 2000 ))
            then
                rm {output}
                touch {output}
            fi
        else
            touch {output}
        fi
        """
