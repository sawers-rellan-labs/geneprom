#!/bin/bash
#SBATCH --job-name=geneprom-proteomes
#SBATCH --account=maize_cpu
#SBATCH --partition=xfer          # internet access (QOS xfer is auto-set)
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=work/fetch_proteomes_%j.log
# Protein FASTA for every genome in config/accessions.tsv, written next to the genome in BZea/ref and indexed:
#   <protein>.fa + .fa.fai       samtools faidx  -> retrieval by ID (samtools faidx X.protein.fa Zm00001eb421930_P001)
#   <protein> BLAST DB (.p*)      makeblastdb -dbtype prot -parse_seqids -> blastp, and blastdbcmd -entry <ID>
# Proteins come from MaizeGDB (download.maizegdb.org/<assembly>/<protein>.gz; the download is kept as .gz).
# RIL003 has no MaizeGDB annotation: its proteins are translated from the Helixer GFF with gffread -y.
# Idempotent (existing files are kept); every file is written as .tmp and renamed when complete.
# Run from the repo root on hazel: sbatch scripts/fetch_proteomes.sbatch
set -eo pipefail
export PATH=/usr/local/apps/apptainer/1.4.2-1/bin:$PATH
REF=/rsstu/users/r/rrellan/BZea/ref
SIF=/share/maize/$USER/apptainer/geneprom.sif
run() { apptainer exec -B "$REF" -B "$PWD" "$SIF" "$@" < /dev/null; }   # </dev/null: keep the loop's stdin
mkdir -p work

tail -n +2 config/accessions.tsv | while IFS=$'\t' read -r acc taxon genome gff annot protein; do
  out=$REF/$protein
  if [ ! -s "$out" ]; then
    if [[ $gff == *helixer* ]]; then
      gzip -dc "$REF/$gff" > "work/${acc}_helixer.gff"
      run gffread -y "$out.tmp" -g "$REF/${genome%.gz}" "work/${acc}_helixer.gff"
    else
      url=https://download.maizegdb.org/${genome%.fa}/${protein}.gz
      curl -sfL --retry 3 -o "$out.gz.tmp" "$url"
      gzip -t "$out.gz.tmp"
      gzip -dc "$out.gz.tmp" > "$out.tmp"
      mv "$out.gz.tmp" "$out.gz"
    fi
    mv "$out.tmp" "$out"
  fi
  [ -s "$out.fai" ] || run samtools faidx "$out"
  db=${out%.fa}
  [ -s "$db.pdb" ] || run makeblastdb -dbtype prot -parse_seqids -in "$out" -out "$db" > /dev/null
  echo -e "$acc\t$(grep -c '>' "$out") proteins\t$out"
done
