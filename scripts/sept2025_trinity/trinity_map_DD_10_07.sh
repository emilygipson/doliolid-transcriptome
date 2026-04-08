#!/bin/bash
#SBATCH --job-name=trinity_map_DD1007
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=02:00:00
#SBATCH --output=trinity_map_DD_10_07.%j.out
#SBATCH --error=trinity_map_DD_10_07.%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

set -euo pipefail
module purge
module load BWA/0.7.18-GCCcore-13.3.0
module load SAMtools

cd /scratch/eeg37520/Sept2025_Trinity

SAMPLE="DD_10_07"
REF="4samp_Trinity.longest_isoform.fasta"
R1="/scratch/eeg37520/Oct2025_133_proc/${SAMPLE}.1.trimmed.fq"
R2="/scratch/eeg37520/Oct2025_133_proc/${SAMPLE}.2.trimmed.fq"
OUT="${SAMPLE}.trinity.sorted.bam"

bwa mem -t 8 "$REF" "$R1" "$R2" | samtools sort -@ 8 -o "$OUT"
samtools index -@ 8 "$OUT"
