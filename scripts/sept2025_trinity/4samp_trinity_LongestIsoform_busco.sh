#!/bin/bash
#SBATCH --job-name=busco_longestisoform_4samptrinity
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=busco_longest_%j.out
#SBATCH --error=busco_longest_%j.err
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL

# Load BUSCO
module load BUSCO/5.8.3-foss-2023a
# Run BUSCO on longest isoform FASTA
busco -i trinity_all_samples_out.Trinity.fasta \
      -l metazoa_odb10 \
      -o busco_longest_out \
      -m transcriptome \
      --cpu 16
