#!/bin/bash
#SBATCH --job-name=bwa_index_onePerGene
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=/scratch/eeg37520/ReferenceVersionAssessments/onePerGene/index/%j.out
#SBATCH --error=/scratch/eeg37520/ReferenceVersionAssessments/onePerGene/index/%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

set -euo pipefail

module purge
module load BWA

mkdir -p /scratch/eeg37520/ReferenceVersionAssessments/onePerGene/index
mkdir -p /scratch/eeg37520/ReferenceVersionAssessments/onePerGene/mapping

cp /scratch/eeg37520/transdecoder_homology/cdhit/one_per_gene/final_ref.cds.onePerGene.fasta \
   /scratch/eeg37520/ReferenceVersionAssessments/onePerGene/index/

bwa index /scratch/eeg37520/ReferenceVersionAssessments/onePerGene/index/final_ref.cds.onePerGene.fasta

echo "Index complete: $(date)"