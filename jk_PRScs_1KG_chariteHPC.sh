## USAGE
# Convert Daner to PRScs sumstat format e.g. with frq and/or info filter
# zcat daner.NAME.gz | awk '{if (NR==1 || ($8>0.9)) print $2,$4,$5,$9,$11}' > prsCS_sum.NAME.Info9.txt
# zcat daner.NAME.gz | awk '{if (NR==1 || ($8>0.9 && $6>0.05 && $6<0.95 && $7>0.05 && $7<0.95)) print $2,$4,$5,$9,$11}' > prsCS_sum.NAME.frq05.Info9.txt
# create a new folder PRScs (workdir) and move sumstats to this folder
# replace at least the following variables: bimfile (target sample), bimloc, outname, file (sumstats), samplesize (GWAS sample size) and condaenv (name of your conda env)
# make sure to install h5py and scipy in your specified condaenv first
# for more info on PRScs usage see: https://github.com/getian107/PRScs
# this script will create PRScs jobfiles for each chromosome and submit them to the cluster
# after all jobs are finished go to the PRScs.out folder in your outdir, check if each file contains output wc -l *txt, merge all chr, no header needed
# clear scratch in-between runs and after the final run (see file in PRScs_job.s folder)
# script PRScs2daner.R can be used to merge PRScs output with daner, replacing OR/BETA and retaining only SNPs found in PRScs output

jobfile="PRScs.job.chr" # jobname
outdir="chr_frq05_i9_beps7_1kg_nobeps" # new subfolder for specific run
workdir="$PWD/PRScs" # subfolder with sumstats
refdir="/sc-projects/sc-proj-cc15-ripke-lab/software/PRScs/ldblk_1kg_eur" # EUR ref
bimfile="scz_beps7_eur_jk-qc2.exSNP.hg19.ch.fl.bgn" # without ending bim
bimloc="/sc-projects/sc-proj-cc15-ripke-lab/projects/kraft/beps7/qc2/qc/imputation/cobg_dir_genome_wide/"
file="prsCS_sum.SCZ3.nobeps.frq05.Info9.txt" # input summary statistics
outname="SCZ3.sumstats.frq05.i9.PRScs.1kg.nobeps"
samplesize=160556 #GWAS sample size
condaenv="julia"


cd ${workdir}
mkdir ${outdir}
cd ${outdir}
mkdir PRScs_job.s # jobscript folder
mkdir PRScs.out # output folder



for i in {1..22}; do echo "#!/bin/bash
#SBATCH -t 1:30:00
#SBATCH -N 1
#SBATCH --mem-per-cpu=8G 

# INPUT
FILE=${file}
WORKDIR=${workdir}
TMPDIRP="/sc-scratch/sc-scratch-cc15-ripke-lab"

# copy to tempdir
cp \$WORKDIR/\$FILE \$TMPDIRP
cp ${bimloc}/${bimfile}.bim \$TMPDIRP

# change to tempdir
cd \$TMPDIRP

# Conda initialization in the bash shell 
eval \"\$(/opt/conda/bin/conda shell.bash hook)\"

# Activate conda virtual environment
conda activate ${condaenv}            
python --version


python /sc-projects/sc-proj-cc15-ripke-lab/software/PRScs/PRScs.py \
--ref_dir=${refdir} \
--bim_prefix=${bimfile} \
--sst_file=${file} \
--n_gwas=${samplesize} \
--out_dir=${outname} \
--chrom=$i \
--seed=666 #\
#--a=1 \
#--b=0.5 \
#--phi=1e-4 \
#--n_iter=1000 \
#--n_burnin=500 \
#--thin=5 \
#--beta_std=false

## note on phi: for well-powered GWAS phi is determined automatically
# with limited GWAS sample size, 1e-2 (highly polgenic) or 1e-4 (less polygenic trait) is adviced
# alternative is a small-scale grid search e.g. phi=1e-6, 1e-4, 1e-2, 1

touch PRScs.chr$i.${outname}.finished


# copy to outdir
cp PRScs.chr$i.${outname}.finished \$WORKDIR/${outdir}/PRScs.out
cp ${outname}* \$WORKDIR/${outdir}/PRScs.out


" > PRScs_job.s/$jobfile.$i.s ;
done


chmod u+x -R PRScs_job.s
cd PRScs_job.s
for i in {1..22}; do sbatch "$jobfile.$i.s"; done

# remove tmp files from scratch
tmpdirp="/sc-scratch/sc-scratch-cc15-ripke-lab"
echo "rm $tmpdirp/${file}" > clearscratch 
echo "rm $tmpdirp/${bimfile}.bim" >> clearscratch
echo "rm $tmpdirp/${outname}*" >> clearscratch


## INITIAL script
#python /sc-projects/sc-proj-cc15-ripke-lab/software/PRScs/PRScs.py \
#--ref_dir=/sc-projects/sc-proj-cc15-ripke-lab/software/PRScs/ldblk_1kg_eur \
#--bim_prefix=PRScs_r1/cvd_belv1_eur_jk-qc3.hg19.ch.fl.bgn \
#--sst_file=prsCS_sum.CAD_CARDIoGRAMplusC4D.trans.hrc.h.gz \
#--n_gwas=184305 \
#--out_dir=PRScs_r1 #\
#--chrom=22


