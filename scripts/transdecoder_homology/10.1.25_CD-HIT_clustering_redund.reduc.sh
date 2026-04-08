#!/bin/bash
#SBATCH --job-name=cdhit_cluster_extract
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=cdhit_cluster_extract_%j.out
#SBATCH --error=cdhit_cluster_extract_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# Robust CD-HIT clustering + CDS extraction
set -euo pipefail

# -----------------------------
# Modules
# -----------------------------
module purge
module load GCC/12.3.0
module load CD-HIT/4.8.1-GCC-12.3.0
module load SeqKit/2.9.0
# try loading seqtk (fast subseq); it's OK if not present (we'll fallback)
module load seqtk/1.4-GCC-13.3.0 2>/dev/null || true

# -----------------------------
# Variables (edit if needed)
# -----------------------------
INPUT_PEP="/scratch/eeg37520/transdecoder_homology/high_conf_debug/rmdup/both_supported.proteins.rmdup.pep"
INPUT_CDS="/scratch/eeg37520/transdecoder_homology/high_conf_debug/rmdup/both_supported.cds.rmdup"

OUTDIR="/scratch/eeg37520/transdecoder_homology/cdhit"
mkdir -p "$OUTDIR"
TMP="$OUTDIR/tmp"
mkdir -p "$TMP"

CPU=${SLURM_CPUS_PER_TASK:-16}
CLUSTER_ID=0.95

OUTPUT_PEP="$OUTDIR/final_ref.proteins.nr95.pep"
OUTPUT_CDS="$OUTDIR/final_ref.cds"

LOG="$OUTDIR/cdhit_extract.log"
echo "CD-HIT + CDS extraction run: $(date)" > "$LOG"
echo "INPUT_PEP: $INPUT_PEP" >> "$LOG"
echo "INPUT_CDS: $INPUT_CDS" >> "$LOG"
echo "" >> "$LOG"

# -----------------------------
# Sanity checks
# -----------------------------
if [[ ! -s "$INPUT_PEP" ]]; then
  echo "[ERROR] Protein FASTA missing or empty: $INPUT_PEP" | tee -a "$LOG"
  exit 2
fi
if [[ ! -s "$INPUT_CDS" ]]; then
  echo "[ERROR] CDS FASTA missing or empty: $INPUT_CDS" | tee -a "$LOG"
  exit 3
fi

echo "Counts before clustering:" | tee -a "$LOG"
echo "  proteins (input): $(grep -c '^>' "$INPUT_PEP")" | tee -a "$LOG"
echo "  cds      (input): $(grep -c '^>' "$INPUT_CDS")" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# -----------------------------
# Step 1: Cluster protein sequences with CD-HIT
# -----------------------------
echo "Running CD-HIT (c=$CLUSTER_ID) ..." | tee -a "$LOG"
cd-hit -i "$INPUT_PEP" -o "$OUTPUT_PEP" -c "$CLUSTER_ID" -n 5 -T "$CPU" -M 0 -d 0 -g 1
if [[ $? -ne 0 ]]; then
  echo "[ERROR] CD-HIT failed" | tee -a "$LOG"
  exit 4
fi
echo "CD-HIT finished. output: $OUTPUT_PEP" | tee -a "$LOG"
echo "  clustered proteins: $(grep -c '^>' "$OUTPUT_PEP")" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# -----------------------------
# Step 2: Build lists of IDs
# -----------------------------
# 2a: representative full IDs from clustered protein FASTA (first token of header)
CLUSTERED_FULL="$TMP/clustered_full_ids.txt"
seqkit seq -n "$OUTPUT_PEP" > "$CLUSTERED_FULL"    # seqkit seq -n prints sequence names (first token)
echo "Clustered (representative) full IDs: $(wc -l < "$CLUSTERED_FULL")" | tee -a "$LOG"

# 2b: CDS header IDs (first token, before any space) from CDS FASTA
CDS_HEADERS="$TMP/cds_header_ids.txt"
grep '^>' "$INPUT_CDS" | sed 's/^>//' | awk '{print $1}' > "$CDS_HEADERS"
echo "CDS header IDs: $(wc -l < "$CDS_HEADERS")" | tee -a "$LOG"

# -----------------------------
# Step 3: Build extraction list
# For each clustered representative:
#   - if exact full id present in CDS headers: use it
#   - else look up any CDS header that has same base id (strip .pN) and use the first found (fallback)
# -----------------------------
FULL_EXTRACT="$TMP/full_ids_to_extract.txt"
MAPPING_LOG="$OUTDIR/cluster_to_cds_mapping.tsv"
MISSING_LOG="$OUTDIR/cluster_missing_no_cds.txt"
: > "$FULL_EXTRACT"
: > "$MAPPING_LOG"
: > "$MISSING_LOG"

# Use awk to build fast in-memory maps to avoid 90k greps in a loop
# Build a map of cds headers (full -> 1) and map of base -> first_full
awk 'NR==FNR { cds[$1]=1; base=$1; sub(/\.[pP][0-9]+$/,"",base); if(!(base in base_map)) base_map[base]=$1; next }
     { id=$1;
       if(id in cds) { print id; print id "\tEXACT" >> "'"$MAPPING_LOG"'" }
       else { base=id; sub(/\.[pP][0-9]+$/,"",base);
              if(base in base_map) { print base_map[base]; print id "\tFALLBACK->" base_map[base] >> "'"$MAPPING_LOG"'" }
              else { print id "\tMISSING" >> "'"$MISSING_LOG"'" }
            }
     }' "$CDS_HEADERS" "$CLUSTERED_FULL" \
  | awk 'NF==1 { print $1 }' > "$FULL_EXTRACT"

# Remove duplicates and keep order
sort -u "$FULL_EXTRACT" > "$FULL_EXTRACT.unlock.txt" && mv "$FULL_EXTRACT.unlock.txt" "$FULL_EXTRACT"

echo "" | tee -a "$LOG"
echo "Full IDs to extract (unique): $(wc -l < "$FULL_EXTRACT")" | tee -a "$LOG"
echo "Mapping log: $MAPPING_LOG (EXACT or FALLBACK entries)" | tee -a "$LOG"
echo "Missing mapping (no CDS header found for base): $(wc -l < "$MISSING_LOG")" | tee -a "$LOG"
if [[ -s "$MISSING_LOG" ]]; then
  echo "  Sample missing IDs:" | tee -a "$LOG"
  head -n 10 "$MISSING_LOG" | tee -a "$LOG"
fi

# If nothing to extract, stop
if [[ $(wc -l < "$FULL_EXTRACT") -eq 0 ]]; then
  echo "[ERROR] No CDS IDs to extract. Aborting." | tee -a "$LOG"
  exit 5
fi

# -----------------------------
# Step 4: Extract CDS sequences (prefer seqtk subseq; fallback to seqkit grep)
# -----------------------------
echo "Extracting CDS sequences to $OUTPUT_CDS" | tee -a "$LOG"
if command -v seqtk >/dev/null 2>&1; then
  echo "Using seqtk subseq (fast)." | tee -a "$LOG"
  seqtk subseq "$INPUT_CDS" "$FULL_EXTRACT" > "$OUTPUT_CDS"
  EXITCODE=$?
else
  echo "seqtk not found; using seqkit grep -n fallback (slower)." | tee -a "$LOG"
  seqkit grep -n -f "$FULL_EXTRACT" "$INPUT_CDS" > "$OUTPUT_CDS"
  EXITCODE=$?
fi

if [[ $EXITCODE -ne 0 ]]; then
  echo "[ERROR] Extraction command failed (exit $EXITCODE)." | tee -a "$LOG"
  exit 6
fi

# -----------------------------
# Step 5: Final checks and summary
# -----------------------------
num_prot_orig=$(grep -c '^>' "$INPUT_PEP")
num_prot_clust=$(grep -c '^>' "$OUTPUT_PEP")
num_cds_orig=$(grep -c '^>' "$INPUT_CDS")
num_cds_out=$(grep -c '^>' "$OUTPUT_CDS" || echo 0)

echo "" | tee -a "$LOG"
echo "Final summary:" | tee -a "$LOG"
echo "  proteins: original=$num_prot_orig clustered=$num_prot_clust" | tee -a "$LOG"
echo "  cds:      original=$num_cds_orig extracted=$num_cds_out" | tee -a "$LOG"

echo ""
echo "Details and logs in: $OUTDIR"
echo "Mapping log: $MAPPING_LOG"
echo "Missing-map log: $MISSING_LOG"
echo "Temporary files: $TMP" | tee -a "$LOG"
echo "Finished at: $(date)" | tee -a "$LOG"