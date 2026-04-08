#!/bin/bash
#SBATCH --job-name=transdecoder_homology.v2
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=transdecoder_homology.v2_%j.out
#SBATCH --error=transdecoder_homology.v2_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# -----------------------------
# Variables
# -----------------------------
SCRATCH_DB="/scratch/eeg37520/uniprot_db"                  # change if needed
UNIPROT_SOURCE="/db/uniprot/20230615/uniprot_sprot.fasta"
TRANSCRIPTOME="clean_transcriptome_assembly.fasta"
PEP="$TRANSCRIPTOME.transdecoder_dir/longest_orfs.pep"
PFAM="/db/pfam/Pfam-A.hmm"
LOGFILE="transdecoder_homology.log"

# -----------------------------
# Load modules
# -----------------------------
module load BLAST+/2.16.0-gompi-2024a
module load HMMER/3.3.2
module load TransDecoder/5.7.1-GCC-12.3.0

# -----------------------------
# Prepare local UniProt BLAST DB
# -----------------------------
mkdir -p $SCRATCH_DB
echo "Copying UniProt to scratch..." > $LOGFILE
cp $UNIPROT_SOURCE $SCRATCH_DB/
cd $SCRATCH_DB

# Build BLAST protein database if not already present
if [ ! -f uniprot_sprot.phr ]; then
    echo "Building BLAST database..." >> $LOGFILE
    makeblastdb -in uniprot_sprot.fasta -dbtype prot >> $LOGFILE 2>&1
fi

# -----------------------------
# Run BLASTP against local UniProt
# -----------------------------
echo "Running BLASTP against UniProt..." >> $LOGFILE
blastp \
  -query $PEP \
  -db $SCRATCH_DB/uniprot_sprot \
  -max_target_seqs 5 \
  -outfmt 6 \
  -evalue 1e-5 \
  -num_threads 16 > blastp.outfmt6 2>> $LOGFILE
echo "BLASTP complete at $(date)" >> $LOGFILE

# -----------------------------
# Run PFAM hmmscan
# -----------------------------
echo "Running PFAM hmmscan..." >> $LOGFILE
hmmscan \
  --cpu 16 \
  --domtblout pfam.domtblout \
  $PFAM \
  $PEP >> $LOGFILE 2>&1
echo "PFAM hmmscan complete at $(date)" >> $LOGFILE

# -----------------------------
# Run TransDecoder.Predict with homology support
# -----------------------------
echo "Running TransDecoder.Predict with homology support..." >> $LOGFILE
TransDecoder.Predict \
  -t $TRANSCRIPTOME \
  --retain_blastp_hits blastp.outfmt6 \
  --retain_pfam_hits pfam.domtblout >> $LOGFILE 2>&1
echo "TransDecoder.Predict complete at $(date)" >> $LOGFILE
echo "Results: ${TRANSCRIPTOME}.transdecoder.pep / .cds / .gff3" >> $LOGFILE
