#### USAGE
# cat .txt files in PRScs.out folder
# source activate base
# conda activate myenv
# R libraries tidyverse and data.table required
# Rscript --vanilla PRScs2daner.R daner.gz PRScs.output.txt


message("STARTING script: PRScs2daner.R")

args = commandArgs(trailingOnly=TRUE)
message(paste0("Input daner file: ", args[1]))
message(paste0("Input PRScs output file: ", args[2]))


message("...loading R libraries...")
library(data.table)
library(tidyverse)


message("...file read-in...")
daner <- fread(args[1], header=T, stringsAsFactors=F)
prscs <- fread(args[2], header=F, stringsAsFactors=F)
colnames(prscs) <- c("CHR","SNP","BP","A1_n","A2_n","EF_PRScs")

message("...replacing A1 effect sizes in daner...")
message(paste0("SNPs in daner: ", nrow(daner)))
message(paste0("SNPs in PRScs output: ", nrow(prscs)))
#names(daner)[names(daner) =="POS"] <- "BP"
out <- left_join(daner, prscs, by=c("CHR","BP","SNP")) 
out <- out %>% mutate(EF_PRScs_2=ifelse(A1==A1_n,exp(EF_PRScs),
					ifelse(A1==A2_n,1/exp(EF_PRScs), NA))) %>% filter(!is.na(EF_PRScs_2))
out %>% select("CHR","SNP","BP","A1","A2","OR","A1_n","A2_n","EF_PRScs", "EF_PRScs_2") %>% head()
message(paste0("SNPs after merging: ", nrow(out)))
eff.plot <- out
out$OR=out$EF_PRScs_2
out$EF_PRScs <- NULL
out$EF_PRScs_2 <- NULL
out$A1_n <- NULL
out$A2_n <- NULL

message("...generating output files...")
out.name <- sub('\\.gz$', '', args[1])

write.table(out, file=paste0(out.name,".PRScs.txt"), sep="\t",  quote=F, row.names=F)
message(paste0("Output file created: ",out.name,".PRScs.txt"))

eff.plot %>% select("OR","EF_PRScs_2") %>% head()

if (dir.exists("PRScs")){
	pdf(file=paste0("PRScs/",out.name,"PRScs.effectSizes.pdf"), width=7, height=6)
	plot(as.numeric(eff.plot$OR), eff.plot$EF_PRScs_2, main="Marginal vs. PRScs posterior effect size")
	dev.off()
	message(paste0("Effect Size plot has been generated in folder /PRScs.")) } else {
		pdf(file=paste0(out.name,"PRScs.effectSizes.pdf"), width=7, height=6)
		plot(as.numeric(eff.plot$OR), eff.plot$EF_PRScs_2, main="Marginal vs. PRScs posterior effect size")
		dev.off()
		message(paste0("Effect Size plot has been generated in current folder.")) }

#pdf(file=paste0("PRScs/",out.name,".effectSizes.pdf"), width=7, height=6)
#plot(eff.plot$OR, exp(eff.plot$EF_PRS_cs), main="Marginal vs. PRScs posterior effect size")
#dev.off()

#message(paste0("Effect Size plot has been generated in folder /PRScs."))

message("FINISHED")
