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
          path("${bam.simpleName}.markdup.bam.bai"),
          path("${bam.simpleName}.markdup.metrics.txt")

  script:
  """
  set -eux
  mkdir -p tmp
  export TMPDIR=$PWD/tmp
  export TEMP=$PWD/tmp
  export TMP=$PWD/tmp
  export _JAVA_OPTIONS="-Djava.io.tmpdir=$PWD/tmp"

  picard MarkDuplicates \
    I=${bam} \
    O=${bam.simpleName}.markdup.bam \
    M=${bam.simpleName}.markdup.metrics.txt \
    REMOVE_DUPLICATES=false \
    ASSUME_SORTED=true \
    VALIDATION_STRINGENCY=SILENT \
    MAX_RECORDS_IN_RAM=250000 \
    TMP_DIR=$PWD/tmp

  picard BuildBamIndex \
    I=${bam.simpleName}.markdup.bam \
    O=${bam.simpleName}.markdup.bam.bai
  """
}

process dedup_bam {
  tag "${bam.simpleName}"
  stageInMode  'symlink'
  stageOutMode 'move'

  publishDir "${params.project_folder}/${picard_output}", mode: 'copy'

  input:
    path bam

  output:
    tuple val(bam.simpleName),
          path("${bam.simpleName}.dedup.bam"),
          path("${bam.simpleName}.dedup.bam.bai"),
          path("${bam.simpleName}.dedup.metrics.txt")

  script:
  """
  set -eux
  mkdir -p tmp
  export TMPDIR=$PWD/tmp
  export TEMP=$PWD/tmp
  export TMP=$PWD/tmp
  export _JAVA_OPTIONS="-Djava.io.tmpdir=$PWD/tmp"

  picard MarkDuplicates \
    I=${bam} \
    O=${bam.simpleName}.dedup.bam \
    M=${bam.simpleName}.dedup.metrics.txt \
    REMOVE_DUPLICATES=true \
    ASSUME_SORTED=true \
    VALIDATION_STRINGENCY=SILENT \
    MAX_RECORDS_IN_RAM=250000 \
    TMP_DIR=$PWD/tmp

  picard BuildBamIndex \
    I=${bam.simpleName}.dedup.bam \
    O=${bam.simpleName}.dedup.bam.bai
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
  mkdir -p tmp
  export TMPDIR=\$PWD/tmp
  export TEMP=\$PWD/tmp
  export TMP=\$PWD/tmp
  export _JAVA_OPTIONS="-Djava.io.tmpdir=\$PWD/tmp"

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
  mkdir -p tmp
  export TMPDIR=$PWD/tmp
  export TEMP=$PWD/tmp
  export TMP=$PWD/tmp
  export _JAVA_OPTIONS="-Djava.io.tmpdir=$PWD/tmp"

  picard CollectAlignmentSummaryMetrics \
    I=${bam} \
    O=${bam.simpleName}.align_summary.txt
  """
}

workflow {

  def outdir = "${params.project_folder}/${picard_output}"
  def target_suffix = do_dedup ? ".dedup.bam" : ".markdup.bam"
  def selectedSamples = null as Set
  def sampleMatches = { name, sid ->
    name == sid || name.startsWith("${sid}_")
  }

  if (params.samples_master) {
    def master = file(params.samples_master)
    assert master.exists() : "samples_master not found: ${params.samples_master}"

    selectedSamples = [] as Set
    master.eachLine { line, n ->
      if (n == 1) return
      if (!line?.trim()) return
      def cols = line.split(',', -1)*.trim()
      if (cols.size() < 1) return

      def sid = cols[0]
      if (!sid) return

      def enabled = cols.size() > 10 ? cols[10]?.toLowerCase() : ''
      if (enabled == '' || enabled == 'true') {
        selectedSamples << sid
      }
    }
    assert !selectedSamples.isEmpty() : "No enabled sample_id found in samples_master: ${params.samples_master}"
  }

  def sorted_bams = Channel
    .fromPath("${params.bwa_output}/*.sorted.bam")
    .filter { bam ->
      if (selectedSamples == null) return true
      def base = bam.simpleName.replaceFirst(/\.sorted$/, '')
      selectedSamples.any { sid -> sampleMatches(base, sid as String) }
    }
    .filter { bam ->
      ! file("${outdir}/${bam.simpleName}${target_suffix}").exists()
    }

  def report_input = do_dedup \
    ? dedup_bam(sorted_bams).map { sample_id, bam, bai, metrics -> tuple(sample_id, bam) } \
    : mark_duplicates(sorted_bams).map { sample_id, bam, bai, metrics -> tuple(sample_id, bam) }

  insert_size(report_input)

  alignment_summary(report_input)
}
