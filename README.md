# geneprom — ZmFd4 / ZmFd9 promoter primers across PanAnd teosintes

Primers to amplify and resequence the region upstream of the ATG of the maize ferredoxins
**ZmFd4** (`Zm00001eb083950`, v4 `Zm00001d003797`) and **ZmFd9** (`Zm00001eb421930`, v4
`Zm00001d025352`) in all published PanAnd *Zea* teosinte assemblies, followed by annotation of
that region. Follows Jia *et al.* (2025, *Nature Plants* 11:643) for ZmFd4 (InDel194, a 604-bp
deletion upstream of the ATG) and the conserved-site primer approach of Gorrón *et al.* (2012).

The pipeline is one Quarto notebook, **`fd_promoter_primers.qmd`**, in R, calling external tools via
`system2()` (same style as `sawers-rellan-labs/primermu`). It runs on Hazel inside an Apptainer
image; a stub mode runs on the laptop.

## Design rules

- **Orthologs:** reciprocal best hit of each B73 CDS against all B73 genes; primary locus on the
  B73-matching chromosome (else any `chr*`); the best hit on an `alt-*` scaffold is the accession's
  second haplotype and must be amplified too. A gene tree of every hit (`results/ferredoxin_tree.png`)
  places all copies among the 11 named B73 ferredoxins.
- **Reverse primer** in the **first CDS exon** (v5 exon 2; v5 exon 1 is a non-coding 5′UTR exon).
- Primer sites chosen by **conservation**: identical and gap-free in every locus (IUPAC degenerate
  bases only if nothing invariant exists, with an invariant 3′ 5 nt).
- **Product ≤ 3,000 bp in every locus**; ranked by the product in the shortest locus, then Primer3
  penalty; backup pairs use different sites.
- **Specificity:** forward e-PCR over every whole genome; an unexpected product disqualifies a pair
  when neither primer has a mismatch in its 3′-most 5 nt.
- Jia's own primers (`config/jia2025_primers.tsv`) are mapped and scored as a benchmark.

## Inputs (assumed present)

Reference data are a starting point, prepared once outside this repo; the notebook checks they
exist and stops with a list of anything missing. For every row of `config/accessions.tsv`, in
`/rsstu/users/r/rrellan/BZea/ref`:

| File | Used for |
|---|---|
| `<assembly>.fa` (plain FASTA) | locus extraction, e-PCR |
| `<assembly>.n*` nucleotide BLAST DB (`-parse_seqids`) | ortholog search |
| `<assembly>_<annotation>.gff3` (RIL003: `_helixer.gff.gz`) | gene models |
| `<assembly>_<annotation>.protein.fa` + `.fai` + `.p*` protein BLAST DB (`-parse_seqids`) | protein retrieval / blastp |
| `<assembly>_EDTA.sorted.gff3.gz` + `.tbi` (B73: `Zm-B73-REFERENCE-NAM-5.0.TE.sorted.gff3.gz`; none for RIL003) | TE track of the annotation maps |

Accessions: B73 v5 (coordinate reference) + TIL01, TIL11 (*parviglumis*), TIL18, TIL25 (*mexicana*),
RIMHU001 (*huehuetenangensis*), Gigi, Momo (*diploperennis*), PI615697 (*nicaraguensis*), RIL003
(*luxurians*, Helixer annotation only).

**How they were prepared (2026-10-05):** genomes and GFFs were already in `BZea/ref`. RIL003 genome
decompressed from `.fa.gz` and its nucleotide BLAST DB built (job 1106909). Protein FASTAs
downloaded from `download.maizegdb.org/<assembly>/` (RIL003: translated from the Helixer GFF with
`gffread -y`), indexed with `samtools faidx` and `makeblastdb -dbtype prot -parse_seqids`
(job 1106876, xfer partition). TE annotations (MaizeGDB EDTA GFFs) downloaded next to each genome and
stored coordinate-sorted, bgzipped and tabix-indexed (job 1108482). The prep scripts are not part of
this repo.

Laptop stub inputs (B73 + TIL18, ±200 kb around each gene) are in `tests/fixtures/`, made by
`scripts/make_stub_fixtures.sh`.

## Running

```bash
# laptop: wiring check on the stub fixtures
quarto render fd_promoter_primers.qmd -P mode:stub --output-dir work/stub/render

# hazel, from the checkout /rsstu/users/r/rrellan/BZea/geneprom
sbatch container/build_container.sbatch   # when container/ changes: /share/maize/$USER/apptainer/geneprom.sif (xfer)
sbatch scripts/render.sbatch              # full run -> results/, docs/fd_promoter_primers.html
```

## Overview diagram

`docs/pipeline.svg`, shown at the top of the report, is a metro map of the notebook sections made with
[nf-metro](https://github.com/seqeralabs/nf-metro) (same style as the zealgt map). It is independent of
the notebook: edit `docs/pipeline.mmd` when sections change and re-render on the laptop with
`nf-metro render docs/pipeline.mmd -o docs/pipeline.svg` (`pip install nf-metro`, Python ≥ 3.11).

## Layout

```
fd_promoter_primers.qmd   # the pipeline — source of truth
config/                   # accessions, Jia 2025 primers, named B73 ferredoxins
container/                # environment.yml (+ pinned lock), Apptainer recipe, build job
scripts/                  # render job, stub-fixture script
tests/fixtures/           # laptop stub inputs
results/                  # tracked deliverables (orthologs, tree, primers, e-PCR hits, maps)
docs/                     # rendered report
work/                     # NOT tracked: regenerated intermediates
```

## Student TODOs (marked `TODO (student)` in the notebook)

Synteny confirmation of orthologs, genome-specific motif background (`fasta-get-markov`),
nitrogen-specific motif set (NLP / NIGT1), LD and sequence-class clustering of promoter variants,
population check with the MaizeGDB 2026 teosinte VCFs.
