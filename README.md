# doliolid-transcriptome

De novo transcriptome assembly for *Dolioletta gegenbauri*, intended as a reference for downstream population genomics.

## Pipeline

1. **Assembly and initial QC** — Trinity de novo co-assembly, longest isoform extraction, BUSCO, read mapping
2. **Contamination screening and decontamination** — Kraken2 against standard database, removal of contaminant taxids
3. **ORF prediction with homology support** — TransDecoder.LongOrfs, BLASTP, PfamScan
4. **Redundancy reduction** — CD-HIT clustering at protein and CDS levels, isoform collapse, exact duplicate removal
5. **Reference version assessment** — BUSCO and read-mapping comparison of candidate references

## Repository structure

```
doliolid-transcriptome/
├── markdowns/                          # Notes
└── scripts/
    ├── sept2025_trinity/               # Assembly, initial QC, contamination screening
    ├── transcript_assembly_downstream/ # Decontamination, ORF prediction, homology support
    ├── transdecoder_homology/          # High-confidence ORFs, redundancy reduction
    ├── oct25_transcriptome_v2/         # Re-screen on cleaned assembly
    └── reference_version_assessments/  # BUSCO comparison of candidate references
```
## Software

| Tool | Purpose |
|------|---------|
| Trinity | De novo transcriptome assembly |
| BUSCO | Assembly completeness assessment |
| Kraken2 | Taxonomic contamination screening |
| TransDecoder | ORF prediction |
| BLAST+ | Homology support |
| PfamScan | Protein domain identification |
| CD-HIT | Sequence redundancy reduction |

