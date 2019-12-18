#!/usr/bin/env nextflow

// FredHutch Nextflow Metagenomic Pipeline
// December 2019
// @Authors Will Frohlich & Sam Minot


//Params default values
params.output_name = "COMBINED_METAGENOMES"
params.output_folder = "./"
params.bam_folder = "bams"

// Define the file explicitly
contig_file = file(params.contigs_file)


//Process to make a contigs database using Anvi'o
process makeContigsDB {
    container "meren/anvio:5.5"
    cpus 4
    memory "8 GB"

    input:
    file contigs from contig_file

    output:
    file "${params.output_name}-CONTIGS.db" into db_for_HMM

    """
#!/bin/bash

set -e

anvi-gen-contigs-database -f ${contigs} \
                          -o ${params.output_name}-CONTIGS.db

    """
}

//Run Hidden Markov Models to decorate your contigs database with hits
process runHMM {
    container "meren/anvio:5.5"
    cpus 4
    memory "8 GB"
    publishDir "${params.output_folder}"

    input: 
    file db_for_HMM 

    output: 
    file "${db_for_HMM}" into HMM_db

    afterScript "rm -rf *"

    """
#!/bin/bash

set -e

anvi-run-hmms -c ${db_for_HMM} \
              --num-threads 4 

    """
}


process setupNCBIcogs {
    container "meren/anvio:5.5"
    cpus 4
    memory "8 GB"
    
    output:
    file "COGS_DIR.tar" into anvio_cogs_tar

    afterScript "rm -rf *"

    """
#!/bin/bash

set -e

anvi-setup-ncbi-cogs --num-threads 4 --cog-data-dir COGS_DIR --just-do-it
tar cvf COGS_DIR.tar COGS_DIR

    """
}

//Use NCBI’s Clusters of Orthologus Groups to annotate database
process annotateGenesWithCogs {
    container "meren/anvio:5.5"
    cpus 4
    memory "8 GB"
    publishDir "${params.output_folder}"
    
    input:
    file contigs_db from HMM_db
    file anvio_cogs_tar
    
    output:
    file "${contigs_db}" into annotated_contigsDB, contigsDB_for_merge

    """
#!/bin/bash

set -e

tar xvf ${anvio_cogs_tar}
anvi-run-ncbi-cogs -c "${contigs_db}" --num-threads 4 --cog-data-dir COGS_DIR
    """
}

//Create a channel with all of the .bam files in bam folder
raw_bam_ch = Channel.fromPath("${params.bam_folder}/*.bam")

//Refine the Bam files
//Outputs both .bam & .bai files
process refineBams {
    container "meren/anvio:5.5"
    cpus 4
    memory "8 GB"
    publishDir "${params.output_folder}"
    
    input: 
    file bam from raw_bam_ch 

    output: 
    set file("${bam.name.replaceAll(/.bam/,"_refined.bam")}"), file("${bam.name.replaceAll(/.bam/,"_refined.bam")}.bai") into bam_ch

        """
#!/bin/bash 

set -e

#Refine the bams and put them in the output folder
anvi-init-bam ${bam} -o ${params.output_folder} \
                     --output-file ${bam.name.replaceAll(/.bam/,"_refined.bam")}

    """
}

//Generate an anvioProfile for each refined bam
process anvioProfile {
    container "meren/anvio:5.5"
    cpus 4
    memory "8 GB"
    publishDir "${params.output_folder}"

    input: 
    set file(bam), file(bai) from bam_ch
    file db from annotated_contigsDB

    output: file "${bam.name.replaceAll('.bam','_PROFILE.db')}" into bam_profiles

    """
#!/bin/bash

set -e

anvi-profile -i ${bam} \
             -c ${db} \
             --sample-name ${bam.name.replaceAll('.bam','')} \
             --output-dir profiles

#Anvio demands an output directory and names each profile PROFILE.db
#rename the profile to be more specific
mv profiles/PROFILE.db ${bam.name.replaceAll('.bam','_PROFILE.db')}

    """
}

//Merge all the profiles
process mergeProfiles {
    container "meren/anvio:5.5"
    cpus 4
    memory "8 GB"
    publishDir "${params.output_folder}"

    input: 
    file profile_list from bam_profiles.collect()
    file contigsDB from contigsDB_for_merge

    output:
    file "${params.output_name}-MERGED-PROFILE.db"
    
    """
#!/bin/bash

set -e

anvi-merge ${profile_list} \
           --contigs-db ${params.output_name}-CONTIGS.db \
           --sample-name ${params.output_name}_MERGED \
           --output-dir profile

#anvi-merge outputs a file called PROFILE.DB
#Rename this file
mv profile/PROFILE.db ${params.output_name}-MERGED-PROFILE.db 

    """
}


