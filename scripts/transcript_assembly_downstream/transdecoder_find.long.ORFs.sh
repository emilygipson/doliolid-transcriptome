#!/bin/bash
#SBATCH --job-name=transdecoder_longorfs
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=transdecoder_longorfs_%j.out
#SBATCH --error=transdecoder_longorfs_%j.err

# -----------------------------
# Load TransDecoder
# -----------------------------
module load TransDecoder/5.7.1-GCC-12.3.0

# -----------------------------
# Set up local Perl library
# -----------------------------
export PERL5LIB=$HOME/perl5/lib/perl5:$PERL5LIB
mkdir -p $HOME/perl5

# Install URI::Escape if not already installed
perl -MCPAN -e 'install URI::Escape' || echo "URI::Escape already installed"

# -----------------------------
# Variables
# -----------------------------
TRANSCRIPTOME="clean_transcriptome_assembly.fasta"
LOGFILE="transdecoder_longorfs.log"

# -----------------------------
# Start log
# -----------------------------
echo "Starting TransDecoder LongOrfs on $(date)" > $LOGFILE
echo "Transcriptome: $TRANSCRIPTOME" >> $LOGFILE
echo "Using 16 threads" >> $LOGFILE
echo "PERL5LIB: $PERL5LIB" >> $LOGFILE

# -----------------------------
# Run TransDecoder.LongOrfs
# -----------------------------
TransDecoder.LongOrfs -t $TRANSCRIPTOME 2>&1 | tee -a $LOGFILE

# -----------------------------
# Log completion
# -----------------------------
echo "Finished TransDecoder LongOrfs on $(date)" >> $LOGFILE
echo "Results directory: ${TRANSCRIPTOME}.tran
