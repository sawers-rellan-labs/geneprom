# geneprom — ZmFd4 / ZmFd9 promoter primers across PanAnd teosintes

Primers to amplify and resequence the region upstream of the ATG of the maize ferredoxins
**ZmFd4** (`Zm00001eb083950`, v4 `Zm00001d003797`) and **ZmFd9** (`Zm00001eb421930`, v4
`Zm00001d025352`) in all published PanAnd *Zea* teosinte assemblies, followed by annotation of
that region. Follows Jia *et al.* (2025, *Nature Plants* 11:643) for ZmFd4 (InDel194, a 604-bp
deletion upstream of the ATG) and the degenerate-primer approach of Gorrón *et al.* (2012).

The pipeline is one Quarto notebook, **`fd_promoter_primers.qmd`**, in R, calling external tools via
`system2()` (same style as `sawers-rellan-labs/primermu`). It runs on Hazel inside an Apptainer
image.

## Design rules

- **Reverse primer:** most conserved site in the **first CDS exon** (v5 exon 2; v5 exon 1 is a
  non-coding 5′UTR exon), required to bind **every** accession; variable positions become IUPAC
  degenerate bases, the 3′-most 5 nt must be invariant.
- **Forward primer:** conserved site upstream giving a Primer3 product of **2,500–3,000 bp**.
- **Specificity:** forward e-PCR over every whole genome — one product per accession, none from
  the paralog (Fd4 ↔ Fd9).
- Jia's own primers (`config/jia2025_primers.tsv`) are mapped and scored as a benchmark.

## Accessions

`config/accessions.tsv`: B73 v5 (coordinate reference) + TIL01, TIL11 (*parviglumis*), TIL18,
TIL25 (*mexicana*), RIMHU001 (*huehuetenangensis*), Gigi, Momo (*diploperennis*), PI615697
(*nicaraguensis*), RIL003 (*luxurians*, Helixer annotation only). Genomes are read from
`/rsstu/users/r/rrellan/BZea/ref` via symlinks in `data/` — nothing is downloaded.

## Running on Hazel

```bash
cd /share/maize/$USER/geneprom
sbatch container/build_container.sbatch            # once: builds /share/maize/$USER/apptainer/geneprom.sif
sbatch scripts/render.sbatch                       # renders fd_promoter_primers.qmd -> docs/
```

## Layout

```
fd_promoter_primers.qmd   # the pipeline — source of truth
config/                   # accessions, Jia 2025 primers
container/                # environment.yml, Apptainer recipe, build job
scripts/                  # Slurm render job
results/                  # tracked deliverables (primer tables, e-PCR hits, maps)
docs/                     # rendered report
data/  work/              # NOT tracked (symlinks to genomes; regenerated intermediates)
```

## Student TODOs (marked `TODO (student)` in the notebook)

Synteny confirmation of orthologs, genome-specific motif background (`fasta-get-markov`),
nitrogen-specific motif set (NLP / NIGT1), LD and sequence-class clustering of promoter variants,
population check with the MaizeGDB 2026 teosinte VCFs.
