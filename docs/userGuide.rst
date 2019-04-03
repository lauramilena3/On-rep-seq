Requirements
============

- Anaconda

You can follow the `installation guide <https://docs.anaconda.com/anaconda/install/>`_ .


Installation
============

Clone github repo::
   
   git clone https://github.com/lauramilena3/On-rep-seq

Create On-rep-seq virtual environment and activate it::
   
   conda env create -n On-rep-seq -f On-rep-seq.yaml
   source activate On-rep-seq

Go into On-rep-seq directory and create symbolic links to your 
basecalled data on the data/basecalled directory::
   
   cd On-rep-seq/
   fastqDir=$yourDataDir
   ln -s $fastqDir/*fastq data/basecalled 

Change ``$yourDataDir`` with the corresponding directory that holds your data.

Running
=======

Note to Os users (Canu) 
-----------------------
If you are using os then you need to edit the config file to set a new directory for canu::
   
   sed -i'.bak' -e 's/Linux-amd64/Darwin-amd64/g' config.yaml

Download kraken database
------------------------

Download kraken database, notice this step can take up to 48 hours::
   
   kraken2-build --download-taxonomy --db db/NCBI-bacteria 
   kraken2-build --download-library bacteria --db db/NCBI-bacteria
   kraken2-build --build --db db/NCBI-bacteria

Running On-rep-seq
------------------

View the number of avaliable cores with::
   
   nproc

Run the snakemake pipeline with the desired number of cores::
   
   snakemake -j nCores

If you are using your laptop we recommend to leave 2 free processors
for other tasks. 

View dag of jobs to visualize the workflow 
++++++++++++++++++++++++++++++++++++++++++

To view the dag run::

   snakemake --dag | dot -Tpdf > dag.pdf




