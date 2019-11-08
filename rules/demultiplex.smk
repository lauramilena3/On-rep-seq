rule demultiplexing_1:
    input:
        BASECALLED_DIR
    output:
        temp(expand(OUTPUT_DIR + "/01_porechopped_data/{barcode}.fastq", barcode=BARCODES))
    params:
        output_dir=OUTPUT_DIR + "/01_porechopped_data"
    conda:
        "envs/On-rep-seq.yaml"
    message:
        "Demultiplexing step 1"
    threads: 16
    shell:
        """
        head -n 25 scripts/logo.txt
        counter=1
        n=$(ls -l {input}/*fastq | wc -l )
        rm -f {params.output_dir}/*fastq
        for filename in {input}/*fastq
        do
            echo "Processing sample $counter/$n"
            run=$(basename -- $filename)
            echo $run
            echo $filename
            echo "porechop -i $filename -b {params.output_dir}/${{run}} -t {threads} --discard_unassigned --verbosity 2 > /dev/null 2>&1"
            porechop -i $filename -b {params.output_dir}/${{run}} -t {threads} --discard_unassigned --verbosity 2 > /dev/null 2>&1
            for bar in dir_$filename/*.fastq
            do
                f=$(basename -- $bar)
                cat $bar >> {params.output_dir}/$f
            done
            rm -rf dir_$filename
            counter=$((counter+1))
        done
        line=$(echo {BARCODES})
        for barcode in $line
        do
            touch {params.output_dir}/$barcode.fastq
        done
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
            if (( {$reads} < 2000 ))
            then
                rm {output}
                touch {output}
            fi
        else
            touch {output}
        fi
        """
