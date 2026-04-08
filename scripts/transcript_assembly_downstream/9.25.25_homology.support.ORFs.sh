#!/bin/bash
#SBATCH --job-name=v2.transdecoder_homology_chunked
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=72:00:00
#SBATCH --output=transdecoder_homology_chunked_%j.out
#SBATCH --error=transdecoder_homology_chunked_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# ==========================================================
# TransDecoder Homology Support with chunked BLASTP
# ==========================================================

module purge
module load GCC/13.3.0
module load TransDecoder/5.7.1-GCC-12.3.0
module load BLAST+/2.16.0-gompi-2024a
module load HMMER/3.4-gompi-2024a
module load SeqKit/2.9.0   # for seqkit split

HMMSCAN_BIN=$(which hmmscan)
if [[ -z "$HMMSCAN_BIN" ]]; then
    echo "[ERROR] hmmscan not found in PATH. Check module load."
    exit 1
fi

# -----------------------------
# Variables
# -----------------------------
TRANSCRIPTOME="clean_transcriptome_assembly.fasta"
PEP="$TRANSCRIPTOME.transdecoder_dir/longest_orfs.pep"
SCRATCH_DB="/scratch/eeg37520/uniprot_db"
UNIPROT_SOURCE="/db/uniprot/20230615/uniprot_sprot.fasta"
PFAM="/db/pfam/34.0-hmmer3.3.2/Pfam-A.hmm"
LOGFILE="transdecoder_homology_chunked.log"
CHUNK_SIZE=10000   # number of sequences per BLASTP chunk

exec > >(tee -a "$LOGFILE") 2>&1

echo "=================================================="
echo "Starting TransDecoder Homology Support Pipeline (Chunked BLASTP)"
echo "Date: $(date)"
echo "Transcriptome: $TRANSCRIPTOME"
echo "PEP file: $PEP"
echo "UniProt source: $UNIPROT_SOURCE"
echo "Pfam HMM: $PFAM"
echo "Scratch DB directory: $SCRATCH_DB"
echo "hmmscan binary: $HMMSCAN_BIN"
echo "=================================================="

# -----------------------------
# Check input files
# -----------------------------
for f in "$PEP" "$UNIPROT_SOURCE" "$PFAM"; do
    if [[ ! -s $f ]]; then
        echo "[ERROR] Required file not found or empty: $f"
        exit 1
    fi
done

# -----------------------------
# Prepare BLAST DB in TMPDIR
# -----------------------------
mkdir -p "$SCRATCH_DB" || { echo "[ERROR] Cannot create $SCRATCH_DB"; exit 1; }
cp "$UNIPROT_SOURCE" "$SCRATCH_DB/" || { echo "[ERROR] Failed to copy UniProt FASTA"; exit 1; }

cp "$SCRATCH_DB/uniprot_sprot.fasta" "$TMPDIR/"
DB_BASENAME="$TMPDIR/uniprot_sprot"

if [[ ! -f "${DB_BASENAME}.pin" ]]; then
    echo "Building BLAST DB locally at $(date)..."
    makeblastdb -in "$DB_BASENAME.fasta" -dbtype prot || { echo "[ERROR] makeblastdb failed"; exit 1; }
else
    echo "BLAST DB already exists in TMPDIR. Skipping makeblastdb."
fi

# -----------------------------
# Split PEP into chunks (by sequences)
# -----------------------------
CHUNK_DIR="$TMPDIR/pep_chunks"
mkdir -p "$CHUNK_DIR"

echo "Splitting PEP file into chunks of $CHUNK_SIZE sequences at $(date)..."
seqkit split -s "$CHUNK_SIZE" -O "$CHUNK_DIR" "$PEP" || {
    echo "[ERROR] seqkit split failed — aborting" >&2
    exit 1
}

# -----------------------------
# Run BLASTP on each chunk in parallel
# -----------------------------
THREADS_PER_CHUNK=4
MAX_JOBS=$(( SLURM_CPUS_PER_TASK / THREADS_PER_CHUNK ))

echo "Running BLASTP on each chunk with $THREADS_PER_CHUNK threads (max $MAX_JOBS chunks at a time) at $(date)..."
N=0
for f in "$CHUNK_DIR"/*.pep; do
    blastp -query "$f" -db "$DB_BASENAME" \
      -max_target_seqs 5 -max_hsps 1 -outfmt 6 -evalue 1e-5 \
      -num_threads "$THREADS_PER_CHUNK" \
      > "$f.blastp.out" 2> "$f.blastp.err" &
    ((N++))
    if (( N % MAX_JOBS == 0 )); then wait; fi
done
wait

echo "Merging BLASTP results at $(date)..."
cat "$CHUNK_DIR"/*.blastp.out > blastp.outfmt6
echo "BLASTP chunked run complete at $(date)."

# -----------------------------
# Run PFAM hmmscan
# -----------------------------
echo "Running hmmscan at $(date)..."
$HMMSCAN_BIN --cpu 16 --domtblout pfam.domtblout "$PFAM" "$PEP" > pfam.log 2> pfam.err
HMM_STATUS=$?
if [[ $HMM_STATUS -ne 0 ]]; then
    echo "[ERROR] hmmscan failed. See pfam.err"
    exit 1
fi

# -----------------------------
# Run TransDecoder.Predict
# -----------------------------
echo "Running TransDecoder.Predict at $(date)..."
TransDecoder.Predict -t "$TRANSCRIPTOME" \
  --retain_blastp_hits blastp.outfmt6 \
  --retain_pfam_hits pfam.domtblout > predict.log 2> predict.err
PREDICT_STATUS=$?
if [[ $PREDICT_STATUS -ne 0 ]]; then
    echo "[ERROR] TransDecoder.Predict failed. See predict.err"
    exit 1
fi

echo "=================================================="
echo "Pipeline complete at $(date)"
echo "Outputs: blastp.outfmt6, pfam.domtblout, predict.log, predict.err, ${TRANSCRIPTOME}.transdecoder.*"
echo "=================================================="
