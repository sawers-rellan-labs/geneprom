#!/bin/bash
#SBATCH --job-name=geneprom-sif
#SBATCH --account=maize_cpu
#SBATCH --partition=xfer          # compute nodes have no internet; xfer does (QOS xfer is auto-set)
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=container/build_%j.log
# Build the geneprom Apptainer image on the xfer partition (internet access).
# Run from the repo root on hazel: sbatch container/build_container.sbatch
set -euo pipefail
export PATH=/usr/local/apps/apptainer/1.4.2-1/bin:$PATH   # the site module needs TMPDIR; call the binary directly

SIF_DIR=/share/maize/$USER/apptainer
export APPTAINER_CACHEDIR=$SIF_DIR/cache
export APPTAINER_TMPDIR=${TMPDIR:-/tmp}/apptainer_$SLURM_JOB_ID
mkdir -p "$APPTAINER_TMPDIR"

apptainer build --fakeroot --force "$SIF_DIR/geneprom.sif" container/geneprom.def
apptainer exec "$SIF_DIR/geneprom.sif" cat /opt/environment.lock.yml > container/environment.lock.yml
echo "built $SIF_DIR/geneprom.sif"
