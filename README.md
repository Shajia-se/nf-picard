# nf-picard

`nf-picard` is a Nextflow DSL2 module for BAM-level duplicate handling and Picard QC.

## What This Module Does

For each input `*.sorted.bam` from `nf-bwa`:
1. Runs `MarkDuplicates` (always) to generate `*.markdup.bam` and duplicate metrics.
2. Optionally removes duplicates (`remove_duplicates=true`) to generate `*.dedup.bam` + index.
3. Runs Picard QC on the selected BAM (dedup if enabled, otherwise markdup):
   - `CollectInsertSizeMetrics`
   - `CollectAlignmentSummaryMetrics`

## Input

- Directory: `params.bwa_output`
- Pattern: `*.sorted.bam`

## Output

Under `${project_folder}/${picard_output}`:
- always:
  - `${sample}.markdup.bam`
  - `${sample}.markdup.metrics.txt`
- when `remove_duplicates=true` (default):
  - `${sample}.dedup.bam`
  - `${sample}.dedup.bam.bai`
  - `${sample}.dedup.metrics.txt`
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

## Project Structure

```text
main.nf
nextflow.config
configs/
  local.config
  slurm.config
```
