#! /bin/bash
# @author: kaiwang

# set -o xtrace

VS_SRC_MATCH="/synosrc/vs.dm816x"
SS_SRC_MATCH="/synosrc/.*/build_env/ds.*"
DS_SRC_MATCH="/synosrc/ds.*"

# ------------------------------------

# WORKDIR is where we start firing build command

if [[ $PWD =~ $SS_SRC_MATCH ]]; then
    WORKDIR=$PWD
	SRCDIR=${WORKDIR%/build_env*}/source/
elif [[ $PWD =~ $VS_SRC_MATCH ]]; then
	WORKDIR=$PWD
    SRCDIR=$WORKDIR/source/vsc_816x/
elif [[ $PWD =~ $DS_SRC_MATCH ]]; then
    WORKDIR=$PWD
    SRCDIR=$WORKDIR/source/
else
	printf "Should call this script under: \n"
	printf "                               $VS_SRC_MATCH \n"
	printf "                               $SS_SRC_MATCH \n"
	printf "                               $DS_SRC_MATCH \n"
	exit 1
fi

echo "new working dir: $WORKDIR"
echo "new source dir:  $SRCDIR"

# change WORKDIR (if no follow link, the .bashrc will be modified and the link will be broken)
sed --follow-symlinks -i "s#^export WORKDIR=.*#export WORKDIR=$WORKDIR#g" ~/.bashrc 
sed --follow-symlinks -i "s#^export SRCDIR=.*#export SRCDIR=$SRCDIR#g" ~/.bashrc 

echo "NOTE: new environment VAR only take effect for new shell session"

