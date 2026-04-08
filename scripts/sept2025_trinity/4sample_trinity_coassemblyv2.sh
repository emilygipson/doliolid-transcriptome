#!/bin/bash
#SBATCH --job-name=trinity_coassemblyv2highmem
#SBATCH --partition=highmem_p
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=500G
#SBATCH --time=96:00:00
#SBATCH --output=trinity_coassemblev2_%j.out
#SBATCH --error=trinity_coassemblev2_%j.err
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL

#this is the recovered version of the job submission script for the job 40480967 after i accidentally deleted eveyrhting in the working directory it was running from (:

# Load Trinity 
module load Trinity/2.15.2-foss-2023a

# Run Trinity co-assembly on all four samples
Trinity \
  --seqType fq \
  --max_memory 200G \
  --CPU ${SLURM_CPUS_PER_TASK} \
  --left  DL5_15_R1.fastq.gz,DL5_17_R1.fastq.gz,DL5_18_R1.fastq.gz,DL5_19_R1.fastq.gz \
  --right DL5_15_R2.fastq.gz,DL5_17_R2.fastq.gz,DL5_18_R2.fastq.gz,DL5_19_R2.fastq.gz \
  --output trinity_all_samples_out