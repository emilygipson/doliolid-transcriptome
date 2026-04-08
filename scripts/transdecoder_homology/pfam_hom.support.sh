#!/bin/bash
#SBATCH --job-name=pfam_scan
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=pfam_scan_%j.out
#SBATCH --error=pfam_scan_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load GCC/13.3.0
module load HMMER/3.4-gompi-2024a

PEP="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.pep"
PFAM="/db/pfam/34.0-hmmer3.3.2/Pfam-A.hmm"
OUTDIR="/scratch/eeg37520/transdecoder_homology"

mkdir -p "$OUTDIR"
cd "$OUTDIR"

echo "Running hmmscan against Pfam-A at $(date)..."
hmmscan --cpu 16 \
  --domtblout pfam.domtblout \
  "$PFAM" \
  "$PEP" > pfam_scan.log 2> pfam_scan.err

STATUS=$?
if [[ $STATUS -ne 0 ]]; then
    echo "[ERROR] hmmscan failed. See pfam_scan.err"
    exit 1
fi

echo "hmmscan finished at $(date). Output: $OUTDIR/pfam.domtblout"
