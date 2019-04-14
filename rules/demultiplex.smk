rule demultiplexing_1:
    input:
        BASECALLED_DIR
    output:
        temp(expand("data/01_porechopped_data/_temp_{barcode}.fastq", barcode=BARCODES))
    params:
        output_dir="data/01_porechopped_data"
    conda:
        "envs/On-rep-seq.yaml"
    message:
        "Demultiplexing step 1"
    threads: 16
    shell:
        """ 
        counter=1
        n=$(ls -l {input}/*fastq | wc -l )
        rm -f {params.output_dir}/*fastq
        #for filename in {input}/*fastq
        #do
        #    echo "Processing sample $counter/$n"
        #    porechop -i $filename -b dir_$filename -t {threads} --discard_unassigned --verbosity 0 > /dev/null 2>&1
        #    for bar in dir_$filename/*.fastq
        #    do
        #        f=$(basename -- $bar)
        #        cat $bar >> {params.output_dir}/$f
        #    done  
        #    rm -rf dir_$filename
        #    counter=$((counter+1))
        #done
        line=$(echo {BARCODES})
        for barcode in $line
        do
            touch {params.output_dir}/$barcode.fastq
            mv {params.output_dir}/$barcode.fastq {params.output_dir}/temp_$barcode.fastq
        done
        """

rule demultiplexing_2:
    input:
        "data/01_porechopped_data/temp_{barcode}_01.fastq" 
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