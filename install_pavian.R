#!/usr/bin/Rscript

ncpus=parallel::detectCores()
options(Ncpus=ncpus)

### this installs but isn't picked up by pavian
#source("https://bioconductor.org/biocLite.R")
#biocLite("GenomicRanges")
#install.packages("BiocManager")
#BiocManager::install("Rsamtools")

install.packages("remotes")
remotes::install_github("fbreitwieser/pavian", upgrade=T, quiet=T)

