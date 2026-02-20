#!/usr/bin/env nextflow
nextflow.enable.dsl=2

def picard_output = params.picard_output ?: "picard_output"
def do_dedup = (params.remove_duplicates == null) ? true : params.remove_duplicates

process mark_duplicates {
  tag "${bam.simpleName}"
  stageInMode  'symlink'
  stageOutMode 'move'

  publishDir "${params.project_folder}/${picard_output}", mode: 'copy'

  input:
    path bam

  output:
    tuple val(bam.simpleName),
          path("${bam.simpleName}.markdup.bam"),
          path("${bam.simpleName}.markdup.metrics.txt")

  script:
  """
  set -eux

  picard MarkDuplicates \
    I=${bam} \
    O=${bam.simpleName}.markdup.bam \
    M=${bam.simpleName}.markdup.metrics.txt \
    REMOVE_DUPLICATES=false \
    ASSUME_SORTED=true \
    VALIDATION_STRINGENCY=SILENT \
    MAX_RECORDS_IN_RAM=250000 \
    TMP_DIR=/tmp

  """
}

process dedup_bam {
  tag "${sample_id}"
  stageInMode  'symlink'
  stageOutMode 'move'

  publishDir "${params.project_folder}/${picard_output}", mode: 'copy'

  input:
    tuple val(sample_id), path(markdup_bam), path(markdup_metrics)

  output:
    tuple val(sample_id),
          path("${sample_id}.dedup.bam"),
          path("${sample_id}.dedup.bam.bai")

  script:
  """
  set -eux

  picard MarkDuplicates \
    I=${markdup_bam} \
    O=${sample_id}.dedup.bam \
    M=${sample_id}.dedup.metrics.txt \
    REMOVE_DUPLICATES=true \
    ASSUME_SORTED=true \
    VALIDATION_STRINGENCY=SILENT \
    MAX_RECORDS_IN_RAM=250000 \
    TMP_DIR=/tmp

  picard BuildBamIndex \
    I=${sample_id}.dedup.bam \
    O=${sample_id}.dedup.bam.bai
  """
}


process insert_size {
  tag "${bam.simpleName}"
  stageInMode  'symlink'
  stageOutMode 'move'

  publishDir "${params.project_folder}/${picard_output}", mode: 'copy'

  input:
    tuple val(sample_id), path(bam)

  output:
    path "${bam.simpleName}.insert_size.txt"
    path "${bam.simpleName}.insert_size.pdf"

  script:
  """
  set -eux

  picard CollectInsertSizeMetrics \
    I=${bam} \
    O=${bam.simpleName}.insert_size.txt \
    H=${bam.simpleName}.insert_size.pdf \
    M=0.5
  """
}

process alignment_summary {
  tag "${bam.simpleName}"
  stageInMode  'symlink'
  stageOutMode 'move'

  publishDir "${params.project_folder}/${picard_output}", mode: 'copy'

  input:
      tuple val(sample_id), path(bam)

  output:
    path "${bam.simpleName}.align_summary.txt"

  script:
  """
  set -eux

  picard CollectAlignmentSummaryMetrics \
    I=${bam} \
    O=${bam.simpleName}.align_summary.txt
  """
}

workflow {

  def outdir = "${params.project_folder}/${picard_output}"
  def target_suffix = do_dedup ? ".dedup.bam" : ".markdup.bam"

  def sorted_bams = Channel
    .fromPath("${params.bwa_output}/*.sorted.bam")
    .filter { bam ->
      ! file("${outdir}/${bam.simpleName}${target_suffix}").exists()
    }

  def marked = mark_duplicates(sorted_bams)
  def report_input = do_dedup \
    ? dedup_bam(marked).map { sample_id, bam, bai -> tuple(sample_id, bam) } \
    : marked.map { sample_id, bam, metrics -> tuple(sample_id, bam) }

  insert_size(report_input)

  alignment_summary(report_input)
}
