#!/bin/bash
#SBATCH --job-name=blastp_chunks66
#SBATCH --partition=batch
#SBATCH --array=0-65       # set to number of chunks minus 1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=blastp_chunk_%A_%a.out
#SBATCH --error=blastp_chunk_%A_%a.err
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=eeg37520@uga.edu

# Load modules
module purge
module load BLAST+/2.16.0-gompi-2024a

# Directories
SCRATCH="/scratch/eeg37520"
CHUNK_DIR="/scratch/eeg37520/transdecoder_homology/pep_chunks"
DB="/scratch/eeg37520/transdecoder_homology/uniprot_sprot_db/uniprot_sprot.fasta"  # BLAST DB basename

# Array task gets the correct chunk
CHUNK_FILES=($CHUNK_DIR/*.pep)
CHUNK=${CHUNK_FILES[$SLURM_ARRAY_TASK_ID]}

# Output file
OUT_FILE="$CHUNK.blastp.out"

echo "Running BLASTP on $CHUNK"
echo "Output: $OUT_FILE"
date

blastp -query $CHUNK \
       -db $DB \
       -max_target_seqs 5 \
       -max_hsps 1 \
       -outfmt 6 \
       -evalue 1e-5 \
       -num_threads $SLURM_CPUS_PER_TASK \
       -out $OUT_FILE

STATUS=$?
if [[ $STATUS -ne 0 ]]; then
    echo "[ERROR] BLASTP failed on $CHUNK with exit code $STATUS"
else
    echo "BLASTP finished successfully for $CHUNK"
fi

date
