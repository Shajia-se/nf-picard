#!/usr/bin/env nextflow
nextflow.enable.dsl=2

def picard_output = params.picard_output ?: "picard_output"

process mark_duplicates {
  tag "${bam.simpleName}"
  stageInMode  'symlink'
  stageOutMode 'move'

  publishDir "${params.project_folder}/${picard_output}", mode: 'copy'

  input:
    path bam

  output:
    tuple val(bam.simpleName), path("${bam.simpleName}.markdup.bam")

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


process insert_size {
  tag "${bam.simpleName}"
  stageInMode  'symlink'
  stageOutMode 'move'

  publishDir "${params.project_folder}/${picard_output}", mode: 'copy'

  input:
    path bam

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
    path bam

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

  def sorted_bams = Channel
    .fromPath("${params.bwa_output}/*.sorted.bam")
    .filter { bam ->
      ! file("${outdir}/${bam.simpleName}.markdup.bam").exists()
    }

  def marked = mark_duplicates(sorted_bams)

  insert_size(marked)

  alignment_summary(marked)
}
