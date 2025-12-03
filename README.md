# nf-picard

<<<<<<< HEAD
A simple, portable Picard-based BAM QC pipeline using Nextflow.
Designed to process aligned BAM files (e.g., from `nf-bwa`) by marking duplicates and generating alignment QC metrics.

---

## 🎯 What this pipeline does

Runs **three core Picard tools** on each sorted BAM:

### 1) **MarkDuplicates**

Marks PCR/optical duplicates (FLAG 0x400).
Does **not** remove duplicates.
Outputs metrics + new indexed BAM.

### 2) **CollectInsertSizeMetrics**

Computes fragment length distribution.
Outputs text summary (+ optional PDF).

### 3) **CollectAlignmentSummaryMetrics**

Reports essential alignment QC:
mapping rate, pairing %, mismatch rate, error rate, read length, chimera %, adapter %, etc.

Produces standardized QC-ready BAMs for downstream filtering (e.g., `nf-chipfilter`) or peak calling.

---

## 🚀 Run on HPC (Slurm + Singularity)

```bash
nextflow run main.nf -profile hpc 
```

* Picard Singularity image:

```
singularity pull picard-2.27.4.sif docker://shajiase/picard:2.27.4
```

## 📤 Output

Each sample produces:

| File                         | Description              |
| ---------------------------- | ------------------------ |
| `SAMPLE.markdup.bam`         | BAM with duplicate flags |
| `SAMPLE.markdup.bam.bai`     | BAM index                |
| `SAMPLE.markdup.metrics.txt` | Duplicate metrics        |
| `SAMPLE.insert_metrics.txt`  | Insert size statistics   |
| `SAMPLE.insert_metrics.pdf`  | Insert size plot         |
| `SAMPLE.align_summary.txt`   | Alignment QC summary     |

Final deliverables for downstream pipelines are:

* `SAMPLE.markdup.bam`
* `SAMPLE.markdup.bam.bai`
* QC reports

---

## 📂 Project structure

```
nf-picard/
├── main.nf
├── nextflow.config
└── configs/
    ├── local.config
    └── slurm.config
=======
## 1. Overview

`nf-picard` is a lightweight Nextflow DSL2 pipeline designed to perform essential BAM-level preprocessing using **Picard**.
It provides standardized duplicate marking and alignment QC metrics for ChIP-seq and ATAC-seq datasets.

This pipeline **marks** PCR/optical duplicates but does **not remove** them, following current ENCODE and nf-core recommendations.
The generated BAM files and QC reports serve as the input for downstream pipelines such as `nf-chipfilter`.

---

## 2. Pipeline Functions

The pipeline runs the following Picard tools for every input BAM file:

### ✔ **MarkDuplicates**

* Identifies duplicate fragments
* Adds duplicate flags (`0x400`) in the BAM
* Does **not** remove duplicates
* Produces duplicate statistics (`*.metrics.txt`)

### ✔ **CollectInsertSizeMetrics**

* Estimates fragment length distributions
* Generates insert size summary statistics

### ✔ **CollectAlignmentSummaryMetrics**

* Reports overall alignment quality:

  * Mapped reads
  * Unique alignments
  * Error rate
  * Read length statistics

---

## 3. Directory Structure

Typical project layout:



---

## 4. Input Requirements

* Sorted BAM files (`*.bam`)
* Index files are optional; Picard will regenerate `.bai` if needed.

Specify your BAM directory in `nextflow.config`:

```groovy
params.picard_raw_bam = "/path/to/bam_files"
params.project_folder = "$PWD"
```

---

## 5. Running the Pipeline

### HPC (SLURM)

```bash
nextflow run main.nf -profile hpc
>>>>>>> 550fbc9 (update readme)
```

---

<<<<<<< HEAD
## ✔️ Summary

`nf-picard` provides:

* Standardized BAM QC (duplicates + fragment size + alignment quality)
* Picard-compatible outputs for ENCODE-style workflows
* Clean inputs for `nf-chipfilter` and MACS2/3 peak calling
=======
## 6. Output Files

Results are placed in:

```
${project_folder}/picard_output/
```

For each sample:

| File                         | Description                    |
| ---------------------------- | ------------------------------ |
| `sample.markdup.bam`         | BAM with duplicate flags added |
| `sample.markdup.bam.bai`     | BAM index                      |
| `sample.markdup.metrics.txt` | Duplicate statistics           |
| `sample.insert_metrics.txt`  | Insert size summary            |
| `sample.align_summary.txt`   | Alignment QC report            |

---

## 7. When to Use This Pipeline

Use `nf-picard` when you need to:

* Prepare BAMs for **ChIP-seq / ATAC-seq / RNA-seq** downstream analysis
* Evaluate basic alignment quality
* Generate duplicate metrics prior to filtering
* Feed clean, standardized BAMs into **nf-chipfilter** or MACS peak calling workflows

---

## 8. Relation to Other Pipelines

`nf-picard` is typically followed by:

➡ **nf-chipfilter** → remove multimappers / blacklist / chrM
➡ **MACS2/3** → peak calling

The output `*.markdup.bam` files are designed to be the **exact input** for nf-chipfilter.

---

如果你满意这个风格，我再继续给你写 **nf-chipfilter** 的英文 README。
>>>>>>> 550fbc9 (update readme)
