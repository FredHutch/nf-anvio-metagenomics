# nf-anvio-metagenomics
Analyze a metagenome with the [anvi'o](http://merenlab.org/software/anvio/) metagenomic pipeline


### Getting Started

The example below assumes the following:

  * [Docker Desktop](https://www.docker.com/products/docker-desktop) installed on your local computer
  * [Nextflow installed](https://nextflow.io) on your computer
  * [Nextflow configuration file](https://sciwiki.fredhutch.org/compdemos/nextflow/) at `~/nextflow.config`

### Input Data

In order to run this workflow, you need:

1. A FASTA file 
2. And BAM files for your contigs

### Running the Workflow

To run the workflow run the BASH script run.sh from your command line interpreter.

### Picking Parameters

Inside the run.sh file:

Use the `--contigs_file` parameter to point the computer to your FASTA

### Visulizing the Meta-Genome

To launch the visual browser for the pan-genome go to 127.0.0.1:80:8080 in your web browser.


For more details on how to setup and navigate this visual browser, check out the amazing Anvi'o
[documentation](http://merenlab.org/2016/11/08/pangenomics-v2/.)

![Example Data](https://github.com/william-frohlich/nf-anvio-metagenomics/raw/master/assets/screenshot.png)

