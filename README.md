# nf-picard

`nf-picard` is a Nextflow DSL2 module for BAM-level duplicate handling and Picard QC.

## What This Module Does

For each input `*.sorted.bam` from `nf-bwa`:
1. Runs `MarkDuplicates` once:
   - `remove_duplicates=true` (default): generate `*.dedup.bam` + index + metrics
   - `remove_duplicates=false`: generate `*.markdup.bam` + index + metrics
2. Runs Picard QC on the selected BAM:
   - `CollectInsertSizeMetrics`
   - `CollectAlignmentSummaryMetrics`

## Input

- Directory: `params.bwa_output`
- Pattern: `*.sorted.bam`

## Output

Under `${project_folder}/${picard_output}`:
- when `remove_duplicates=true` (default):
  - `${sample}.dedup.bam`
  - `${sample}.dedup.bam.bai`
  - `${sample}.dedup.metrics.txt`
- when `remove_duplicates=false`:
  - `${sample}.markdup.bam`
  - `${sample}.markdup.bam.bai`
  - `${sample}.markdup.metrics.txt`
- QC reports (based on selected BAM):
  - `${sample}.insert_size.txt`
  - `${sample}.insert_size.pdf`
  - `${sample}.align_summary.txt`

## Key Parameters

- `bwa_output`: input BAM folder
- `picard_output`: output folder name
- `remove_duplicates`: whether to produce/use deduplicated BAM (default: `true`)
- `cpus`, `memory`, `time`: compute resources

## Run

```bash
nextflow run main.nf -profile local
```

```bash
nextflow run main.nf -profile hpc
```

Disable duplicate removal:

```bash
nextflow run main.nf -profile hpc --remove_duplicates false
```

Resume:

```bash
nextflow run main.nf -profile hpc -resume
```

## Notes

- This module is designed to feed `nf-chipfilter`.
- `nf-chipfilter` can prioritize `*.dedup.bam` (recommended) and fall back to `*.markdup.bam`.
- Temporary files are written under the task work directory (`$PWD/tmp`) to avoid shared `/tmp` space issues.

## Project Structure

```text
main.nf
nextflow.config
configs/
  local.config
  slurm.config
```
