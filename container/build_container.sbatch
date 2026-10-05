#!/bin/bash
#SBATCH --job-name=geneprom-sif
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=container/build_%j.log
# Build the geneprom Apptainer image. Run from the repo root: sbatch container/build_container.sbatch
set -euo pipefail
module load apptainer/1.4.2-1

SIF_DIR=/share/maize/$USER/apptainer
export APPTAINER_CACHEDIR=$SIF_DIR/cache
export APPTAINER_TMPDIR=${TMPDIR:-/tmp}/apptainer_$SLURM_JOB_ID
mkdir -p "$APPTAINER_TMPDIR"

apptainer build --fakeroot --force "$SIF_DIR/geneprom.sif" container/geneprom.def
apptainer exec "$SIF_DIR/geneprom.sif" cat /opt/environment.lock.yml > container/environment.lock.yml
rm -rf "$APPTAINER_TMPDIR"
echo "built $SIF_DIR/geneprom.sif"
