#!/bin/bash
#SBATCH --job-name=map_trinity_dd1111
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=02:00:00
#SBATCH --output=map_trinity_dd1111.%j.out
#SBATCH --error=map_trinity_dd1111.%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

set -euo pipefail
module purge
module load BWA/0.7.18-GCCcore-13.3.0
module load SAMtools

cd /scratch/eeg37520/Sept2025_Trinity

bwa mem -t 8 \
  4samp_Trinity.longest_isoform.fasta \
  /scratch/eeg37520/Oct2025_133_proc/DD_11_11.1.trimmed.fq \
  /scratch/eeg37520/Oct2025_133_proc/DD_11_11.2.trimmed.fq | \
  samtools sort -@ 8 -o DD_11_11.trinity.sorted.bam
