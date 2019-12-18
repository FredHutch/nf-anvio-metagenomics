#!/bin/bash

# Script to run nextflow metagenomic pipeline
# @Authors Will Frohlich & Sam Minot

set -e
# Change "EXAMPLE_OUTPUT" to something that describes this group of genomes
OUTPUT_NAME=METAGENOMICS


NXF_VER=19.10.0 nextflow \
    -C ~/nextflow.config \
    run \
    metagenomics.nf \
    --contigs_file contigs.fa \
    --output_folder output \
    --bam_folder bams \
    --output_name $OUTPUT_NAME \
    -work-dir [insert your work dir] \
    --list-collections \
    -process.queue mixed \
    -resume

docker \
    run \
    -p 127.0.0.1:80:8080/tcp \
    -v $PWD:/share \
        meren/anvio:5.5 \
            anvi-interactive \
            -p /share/output/$OUTPUT_NAME-MERGED-PROFILE.db \
            -c /share/output/$OUTPUT_NAME-CONTIGS.db
