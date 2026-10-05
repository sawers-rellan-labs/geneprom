#!/usr/bin/env bash
# Cut the laptop stub fixtures: B73 and TIL18, +-200 kb around ZmFd4 (chr2) and ZmFd9 (chr10).
# Run once on the laptop: bash scripts/make_stub_fixtures.sh
# Output (tracked, ~1.7 MB): tests/fixtures/{B73,TIL18}.fa + .gff3. Each slice is one FASTA record named
# after its chromosome; GFF coordinates are shifted to the slice so both files stay consistent.
# Inputs: local B73 v5 (Ensembl naming "2", "10") and TIL18 genomes; the TIL18 GFF slice is read from hazel
# (data only, by ssh, as allowed by the hpc-debug-loop rules).
set -euo pipefail
OUT=tests/fixtures; mkdir -p "$OUT" work/fai
FLANK=200000
B73_FA=$HOME/ref/zea/Zea_mays.Zm-B73-REFERENCE-NAM-5.0.dna.toplevel.fa
B73_GFF=$HOME/ref/zea/Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.gff3
TIL18_FA=$HOME/ref/zea/Zx-TIL18-REFERENCE-PanAnd-1.0.fa
TIL18_GFF=/rsstu/users/r/rrellan/BZea/ref/Zx-TIL18-REFERENCE-PanAnd-1.0_Zx00002aa.1.gff3

# accession  fasta_name  chrom  gene_start gene_end (CDS hits / gene models)
slices() {
  cat <<EOF
B73	2	chr2	59574299	59577014
B73	10	chr10	116703178	116706315
TIL18	chr2	chr2	89160352	89160819
TIL18	chr10	chr10	111727230	111727676
EOF
}

for acc in B73 TIL18; do : > "$OUT/$acc.fa"; : > "$OUT/$acc.gff3"; done
echo "##gff-version 3" | tee "$OUT/B73.gff3" > "$OUT/TIL18.gff3"

slices | while IFS=$'\t' read -r acc src chr s e; do
  fa=$B73_FA; [ "$acc" = TIL18 ] && fa=$TIL18_FA
  from=$((s - FLANK)); to=$((e + FLANK)); off=$((from - 1))
  samtools faidx --fai-idx "work/fai/$(basename "$fa").fai" "$fa" "$src:$from-$to" | sed "1s/.*/>$chr/" >> "$OUT/$acc.fa"
  if [ "$acc" = B73 ]; then
    awk -F'\t' -v OFS='\t' -v c="$chr" -v a="$from" -v b="$to" -v o="$off" \
      '$1==c && $3!="chromosome" && $4>=a && $5<=b {$4-=o; $5-=o; print}' "$B73_GFF" >> "$OUT/B73.gff3"
  else
    ssh -n -o BatchMode=yes hazel "awk -F'\t' -v OFS='\t' -v c=$chr -v a=$from -v b=$to -v o=$off \
      '\$1==c && \$4>=a && \$5<=b {\$4-=o; \$5-=o; print}' $TIL18_GFF" >> "$OUT/TIL18.gff3"
  fi
done
samtools faidx "$OUT/B73.fa"; samtools faidx "$OUT/TIL18.fa"
ls -la "$OUT"
