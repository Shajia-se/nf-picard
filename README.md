# nf-picard

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
```

---

## ✔️ Summary

`nf-picard` provides:

* Standardized BAM QC (duplicates + fragment size + alignment quality)
* Picard-compatible outputs for ENCODE-style workflows
* Clean inputs for `nf-chipfilter` and MACS2/3 peak calling


---

如果你愿意，我可以继续帮你做一个 **三条 pipeline 的统一文档**（mapping → QC → filtering）让整个流程更清晰。
