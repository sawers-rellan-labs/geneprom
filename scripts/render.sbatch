#!/bin/bash
#SBATCH --job-name=geneprom-render
#SBATCH --account=maize_cpu
#SBATCH --partition=compute_partners
#SBATCH --qos=short                # <= 2 h
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --output=work/render_%j.log
# Full run of fd_promoter_primers.qmd inside the geneprom image (no network needed).
# Run from the repo root on hazel: sbatch scripts/render.sbatch
# Results: results/ (tracked), report: docs/fd_promoter_primers.html
set -eo pipefail
export PATH=/usr/local/apps/apptainer/1.4.2-1/bin:$PATH
SIF=/share/maize/$USER/apptainer/geneprom.sif
[ -f "$SIF" ] || { echo "missing $SIF: run sbatch container/build_container.sbatch first"; exit 1; }
mkdir -p work
apptainer exec -B /rsstu/users/r/rrellan/BZea/ref -B "$PWD" "$SIF" \
  quarto render fd_promoter_primers.qmd -P mode:full
