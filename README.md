# doliolid-transcriptome

Trinity-based transcriptome assembly and annotation pipeline for *Dolioletta gegenbauri*.

## Overview

De novo transcriptome assembly from RNA-seq reads, followed by contamination screening, ORF prediction, homology-based filtering, redundancy reduction, and reference version assessment for downstream population genomics use.

## Repository structure
```
doliolid-transcriptome/
├── README.md
├── markdowns/                          # walkthroughs (in progress)
└── scripts/
    ├── sept2025_trinity/               # Trinity assembly, initial QC, longest isoform, Kraken2 screening
    ├── transcript_assembly_downstream/ # decontamination, TransDecoder ORF prediction, homology support
    ├── transdecoder_homology/          # high-confidence ORF subset, CD-HIT redundancy reduction, BLASTP, PFAM
    ├── oct25_transcriptome_v2/         # post-cleanup Kraken2 re-screen
    └── reference_version_assessments/  # BUSCO comparison of candidate reference versions (onePerGene vs noChimera)
```

## Pipeline phases

1. **Assembly** — Trinity de novo co-assembly (4 samples)
2. **Initial QC** — BUSCO, assembly stats, read mapping
3. **Longest isoform extraction** — one transcript per Trinity gene
4. **Contamination screening** — Kraken2 against standard database
5. **Decontamination** — removal of contaminant taxids
6. **ORF prediction** — TransDecoder.LongOrfs with BLASTP homology support
7. **High-confidence subset + redundancy reduction** — CD-HIT clustering at protein and CDS levels, isoform collapse, exact duplicate removal
8. **Functional annotation** — chunked BLASTP against UniProt, PFAM domain scanning
9. **Re-screen** — Kraken2 on the cleaned v2 assembly
10. **Reference version assessment** — BUSCO and read-mapping comparison of candidate final references

## Software

- Trinity 2.15.2
- BUSCO
- Kraken2
- TransDecoder
- BLAST+ (BLASTP)
- CD-HIT
- PfamScan / HMMER
- BWA
- SAMtools
