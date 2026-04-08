#!/bin/bash
#SBATCH --job-name=map_noChimera
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=08:00:00
#SBATCH --output=/scratch/eeg37520/ReferenceVersionAssessments/noChimera/mapping/%j_%a.out
#SBATCH --error=/scratch/eeg37520/ReferenceVersionAssessments/noChimera/mapping/%j_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --array=1-100%20

set -euo pipefail

module purge
module load SAMtools
module load BWA

READ_DIR="/scratch/eeg37520/Oct2025_133_proc/clean_dedup_files"
SAMPLE_LIST="/scratch/eeg37520/doliolid_popgen/top100/metadata/top100_samples.txt"
REF="/scratch/eeg37520/ReferenceVersionAssessments/noChimera/index/final_ref.cds.noChimera.fasta"
OUT_DIR="/scratch/eeg37520/ReferenceVersionAssessments/noChimera/mapping"
THREADS="${SLURM_CPUS_PER_TASK}"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}" | tr -d '\r' | xargs)

if [[ -z "${SAMPLE}" ]]; then
  echo "ERROR: No sample found for task ${SLURM_ARRAY_TASK_ID}" >&2
  exit 1
fi

R1="${READ_DIR}/${SAMPLE}_unclassified__1.fq"
R2="${READ_DIR}/${SAMPLE}_unclassified__2.fq"

echo "======================================"
echo "Task: ${SLURM_ARRAY_TASK_ID}"
echo "Sample: ${SAMPLE}"
echo "Start time: $(date)"
echo "Threads: ${THREADS}"
module list
echo "======================================"

if [[ ! -f "${REF}.bwt" && ! -f "${REF}.0123" ]]; then
  echo "ERROR: BWA index not found for ${REF}" >&2
  exit 1
fi

if [[ ! -f "${R1}" || ! -f "${R2}" ]]; then
  echo "WARNING: Missing reads for ${SAMPLE}" >&2
  echo "${SAMPLE}" >> "${OUT_DIR}/missing_pairs.txt"
  exit 0
fi

OUT_BAM="${OUT_DIR}/${SAMPLE}.noChimera.sorted.bam"

bwa mem -t "${THREADS}" "${REF}" "${R1}" "${R2}" \
  | samtools sort -@ "${THREADS}" -o "${OUT_BAM}"

samtools index "${OUT_BAM}"
samtools flagstat "${OUT_BAM}" > "${OUT_DIR}/${SAMPLE}.flagstat.txt"

echo "Finished sample ${SAMPLE} at $(date)"