#!/bin/bash
#SBATCH --job-name=trinity_map_all
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=06:00:00
#SBATCH --array=1-133
#SBATCH --output=trinity_map_%A_%a.out
#SBATCH --error=trinity_map_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

set -euo pipefail

module purge
module load BWA/0.7.18-GCCcore-13.3.0
module load SAMtools

cd /scratch/eeg37520/Sept2025_Trinity

REF="4samp_Trinity.longest_isoform.fasta"
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" trinity_samples.txt)

R1="/scratch/eeg37520/Oct2025_133_proc/${SAMPLE}.1.trimmed.fq"
R2="/scratch/eeg37520/Oct2025_133_proc/${SAMPLE}.2.trimmed.fq"

OUT="/scratch/eeg37520/triage_batch_bams/${SAMPLE}.trinity.sorted.bam"

bwa mem -t 8 "$REF" "$R1" "$R2" | samtools sort -@ 8 -o "$OUT"
samtools index -@ 8 "$OUT"
