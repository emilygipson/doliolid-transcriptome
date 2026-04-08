#!/bin/bash
#SBATCH --job-name=pfam_scan_array
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4         # hmmscan threads per chunk
#SBATCH --mem=8G                  # memory per chunk
#SBATCH --time=12:00:00           # wall time per chunk
#SBATCH --array=0-65              # adjust to (number_of_chunks - 1)
#SBATCH --output=pfam_scan_%A_%a.out
#SBATCH --error=pfam_scan_%A_%a.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load GCC/13.3.0
module load HMMER/3.4-gompi-2024a

# Paths
CHUNK_DIR="/scratch/eeg37520/transdecoder_homology/pep_chunks"
PFAM="/db/pfam/34.0-hmmer3.3.2/Pfam-A.hmm"

# Pick the chunk file for this array task
CHUNK_FILE=$(printf "$CHUNK_DIR/longest_orfs.part_%02d.pep" ${SLURM_ARRAY_TASK_ID})
OUT_FILE="${CHUNK_FILE}.pfam.domtblout"

echo "Running hmmscan on $CHUNK_FILE at $(date)..."
hmmscan --cpu $SLURM_CPUS_PER_TASK \
  --domtblout "$OUT_FILE" \
  "$PFAM" \
  "$CHUNK_FILE" > "${CHUNK_FILE}.pfam.log" 2> "${CHUNK_FILE}.pfam.err"

STATUS=$?
if [[ $STATUS -ne 0 ]]; then
    echo "[ERROR] hmmscan failed on $CHUNK_FILE. See ${CHUNK_FILE}.pfam.err"
    exit 1
fi

echo "hmmscan finished at $(date). Output: $OUT_FILE"
