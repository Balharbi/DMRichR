#' annotateCpGs
#' @description Annotates DMRs from \code{dmrseq::dmrseq()} with CpG annotations using \code{annotatr} and returns a \code{ggplot2}
#' @param siRegions A \code{GRanges} object of signficant DMRs returned by \code{dmrseq:dmrseq()}
#' @param regions A \code{GRanges} object of background regions returned by \code{dmrseq:dmrseq()}
#' @param genome A character vector specifying the genome of interest ("hg38" or "mm10")
#' @param saveAnnotations A logical indicating whether to save bed files of annoation database for external enrichment testing
#' @return A \code{ggplot} object of top significant GO and pathway terms from an \code{enrichR} or \code{rGREAT} analysis.
#'  that can be viewed by calling it, saved with \code{ggplot2::ggsave()}, or further modified by adding \code{ggplot2} syntax.
#' @import annotatr
#' @export annotateCpGs
annotateCpGs <- function(sigRegions = sigRegions,
                         regions = regions,
                         genome = genome,
                         saveAnnotations = F){
  stopifnot(genome == "hg38" | genome == "mm10" | genome == "rn6")
  cat("\n[DMRichR] Building CpG annotations \t\t\t", format(Sys.time(), "%d-%m-%Y %X"), "\n")
  annotations <- build_annotations(genome = genome, annotations = paste(genome,"_cpgs", sep=""))
  annotations <- GenomeInfoDb::keepStandardChromosomes(annotations, pruning.mode = "coarse")
  
  glue::glue("Annotating DMRs...")
  dm_annotated_CpG <- annotate_regions(
    regions = sigRegions,
    annotations = annotations,
    ignore.strand = TRUE,
    quiet = FALSE)
  
  glue::glue("Annotating background regions...")
  background_annotated_CpG <- annotate_regions(
    regions = regions,
    annotations = annotations,
    ignore.strand = TRUE,
    quiet = FALSE)
  
  if(saveAnnotations == T){
    glue::glue("Saving files for GAT...")
    if(dir.exists("Extra") == F){dir.create("Extra")}
    CpGs <- as.data.frame(annotations)
    CpGs <- CpGs[!grepl("_", CpGs$seqnames), ]
    table(CpGs$seqnames)
    DMRichR::df2bed(CpGs[, c(1:3,10)], paste("Extra/GAT/", genome, "CpG.bed", sep = ""))
  }

  glue::glue("Preparing CpG annotation plot...")
  CpG_bar <- plot_categorical(
    annotated_regions = dm_annotated_CpG,
    annotated_random = background_annotated_CpG,
    x = 'direction',
    fill = 'annot.type',
    x_order = c('Hypermethylated','Hypomethylated'),
    fill_order = c(
      paste(genome,"_cpg_islands", sep = ""),
      paste(genome,"_cpg_shores", sep = ""),
      paste(genome,"_cpg_shelves", sep = ""),
      paste(genome,"_cpg_inter", sep = "")
      ),
    position = 'fill',
    plot_title = '',
    legend_title = 'Annotations',
    x_label = '',
    y_label = 'Proportion') +
    scale_x_discrete(labels = c("All", "Hypermethylated", "Hypomethylated", "Background")) +
    scale_y_continuous(expand = c(0,0)) +
    theme_classic() +
    theme(axis.text = element_text(size = 25),
          axis.title = element_text(size = 25),
          strip.text = element_text(size = 25),
          #legend.position = "none",
          axis.text.x = element_text(angle = 45,
                                     hjust = 1)) %>%
    return()
}

#' annotateGenic
#' @description Annotates DMRs from \code{dmrseq::dmrseq()} with genic annotations using \code{annotatr} and returns a \code{ggplot2}
#' @param siRegions A \code{GRanges} object of signficant DMRs returned by \code{dmrseq:dmrseq()}
#' @param regions A \code{GRanges} object of background regions returned by \code{dmrseq:dmrseq()}
#' @param genome A character vector specifying the genome of interest ("hg38" or "mm10")
#' @param saveAnnotations A logical indicating whether to save bed files of annoation database for external enrichment testing
#' @return A \code{ggplot} object of top significant GO and pathway terms from an \code{enrichR} or \code{rGREAT} analysis.
#'  that can be viewed by calling it, saved with \code{ggplot2::ggsave()}, or further modified by adding \code{ggplot2} syntax.
#' @import annotatr
#' @export annotateGenic
annotateGenic <- function(sigRegions = sigRegions,
                          regions = regions,
                          genome = genome,
                          saveAnnotations = F){
  stopifnot(genome == "hg38" | genome == "mm10" | genome == "rn6")
  cat("\n[DMRichR] Building gene region annotations \t\t", format(Sys.time(), "%d-%m-%Y %X"), "\n")
  annotations <- build_annotations(genome = genome, annotations = c(paste(genome,"_basicgenes", sep = ""),
                                                                    paste(genome,"_genes_intergenic", sep = ""),
                                                                    paste(genome,"_genes_intronexonboundaries", sep = ""),
                                                                    if(genome == "hg38" | genome == "mm10"){paste(genome,"_enhancers_fantom", sep = "")})) %>%
    GenomeInfoDb::keepStandardChromosomes(., pruning.mode = "coarse")
  
  if(saveAnnotations == T){
    glue::glue("Saving files for GAT...")
    if(dir.exists("Extra") == F){dir.create("Extra")}
    annoFile <- as.data.frame(annotations)
    annoFile <- annoFile[!grepl("_", annoFile$seqnames) ,]
    table(annoFile$seqnames)
    annoFile <- annoFile[, c(1:3,10)]
    
    if(genome == "hg38" | genome == "mm10"){DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_enhancers_fantom", sep = ""), ], "Extra/GAT/enhancers.bed")}
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_promoters", sep = ""), ], "Extra/GAT/promoters.bed")
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_introns", sep = ""), ], "Extra/GAT/introns.bed")
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_intronexonboundaries", sep = ""), ], "Extra/GAT/boundaries.bed")
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_intergenic", sep = ""), ], "Extra/GAT/intergenic.bed")
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_exons", sep = ""), ], "Extra/GAT/exons.bed")
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_5UTRs", sep = ""), ], "Extra/GAT/fiveUTRs.bed")
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_3UTRs", sep = ""), ], "Extra/GAT/threeUTRs.bed")
    DMRichR::gr2bed(annoFile[annoFile$type == paste(genome,"_genes_1to5kb", sep = ""), ], "Extra/GAT/onetofivekb.bed")
  }
  
  glue::glue("Annotating DMRs...")
  dm_annotated <- annotate_regions(
    regions = sigRegions,
    annotations = annotations,
    ignore.strand = TRUE,
    quiet = FALSE)
  
  glue::glue("Annotating background regions...")
  background_annotated <- annotate_regions(
    regions = regions,
    annotations = annotations,
    ignore.strand = TRUE,
    quiet = FALSE)
  
  glue::glue("Preparing CpG annotation plot...")
  gene_bar <- plot_categorical(
    annotated_regions = dm_annotated,
    annotated_random = background_annotated,
    x = 'direction',
    fill = 'annot.type',
    x_order = c('Hypermethylated','Hypomethylated'),
    fill_order =  c(
      if(genome == "hg38" | genome == "mm10"){paste(genome, "_enhancers_fantom", sep = "")},
      paste(genome,"_genes_1to5kb", sep = ""),
      paste(genome,"_genes_promoters", sep = ""),
      paste(genome,"_genes_5UTRs", sep = ""),
      paste(genome,"_genes_exons", sep = ""),
      paste(genome,"_genes_intronexonboundaries", sep = ""),
      paste(genome,"_genes_introns", sep = ""),
      paste(genome,"_genes_3UTRs", sep = ""),
      paste(genome,"_genes_intergenic", sep = "")
      ),
    position = 'fill',
    plot_title = '',
    legend_title = 'Annotations',
    x_label = '',
    y_label = 'Proportion') +
    scale_x_discrete(labels = c("All", "Hypermethylated", "Hypomethylated", "Background")) +
    scale_y_continuous(expand = c(0,0)) +
    theme_classic() +
    theme(axis.text = element_text(size = 25),
          axis.title = element_text(size = 25),
          strip.text = element_text(size = 25),
          #legend.position = "none",
          axis.text.x = element_text(angle = 45,
                                     hjust = 1)) %>%
    return()
}
