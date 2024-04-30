# PRScs analysis script


## Transform initial sumstats (e.g. starting from daner format) and set INFO and FRQ filter

`zcat daner.NAME.gz | awk '{if (NR==1 || ($8>0.9)) print $2,$4,$5,$9,$11}' > prsCS_sum.NAME.Info9.txt`

`zcat daner.NAME.gz | awk '{if (NR==1 || ($8>0.9 && $6>0.05 && $6<0.95 && $7>0.05 && $7<0.95)) print $2,$4,$5,$9,$11}' > prsCS_sum.NAME.frq05.Info9.txt`

Create a new folder in working directory and move transformed sumstats into the new folder:

`mkdir PRScs`

`mv prsCS_sum.NAME.frq05.Info9.txt PRScs/`

## Run PRScs using job scripts

This script may need adaptation depending on server & available environments. 

Replace at least the following variables: bimfile (target sample), bimloc, outname, file (sumstats), samplesize (GWAS sample size) and condaenv (name of your conda env)

This script will generate PRScs job scripts for each chromosome and submit these to the cluster.

`./jk_PRScs_1KG_chariteHPC.sh`

After jobs are successfully run, go to subdir `PRScs/$outdir/PRScs.out` and merge output from all chromosomes:

`wc -l *txt`

## Convert PRScs output to daner formatted summary statistics

load R environment or conda

`Rscript --vanilla PRScs2daner.R daner.gz PRScs.output.txt`
