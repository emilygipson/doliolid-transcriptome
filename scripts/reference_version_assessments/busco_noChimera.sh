#!/bin/bash
#SBATCH --job-name=busco_noChimera
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=/scratch/eeg37520/ReferenceVersionAssessments/%j.out
#SBATCH --error=/scratch/eeg37520/ReferenceVersionAssessments/%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

cd /scratch/eeg37520/ReferenceVersionAssessments

module load BUSCO/5.8.3-foss-2023a

busco \
    -i /scratch/eeg37520/transdecoder_homology/cdhit/one_per_gene/chimera_detect/final_ref.cds.noChimera.fasta \
    -o busco_noChimera_out \
    -m transcriptome \
    -l metazoa_odb10 \
    -c 16 \
    -f