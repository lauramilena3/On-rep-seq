#!/bin/bash
## Maciek Sykulski <macieksk@gmail.com>, 2019
set -eu

#DEFOUTFILE="runnable_jupyter_on-rep-seq_flowgrams_clustering_heatmaps.execution_result.html" ;
DEFOUTFILE="runnable_jupyter_on-rep-seq_flowgrams_clustering_heatmaps.execution_result.ipynb" ; 

function usage {
    echo -e "\n\tUsage: $(basename "$0") [-h|--help] <rep_sample_dir> [output_file ending with .ipynb or .html]"
    echo -e ""
    echo -e "\trep_sample_dir\tdirectory containing rep*.txt files with read lengths counts"
    echo -e "\toutput_file\tname of the jupyter execution result (default: $DEFOUTFILE )"
    echo -e ""
}

SCRIPTDIR="$( cd "$( dirname "$(realpath "${BASH_SOURCE[0]}")" )" && pwd )" 
NBTOEXEC="${SCRIPTDIR}/runnable_jupyter_on-rep-seq_flowgrams_clustering_heatmaps.ipynb"

if [ "$#" -ge 1 ]; then REPSAMPDIR="$1" ;
#else  REPSAMPDIR="../data/Lukas180425/peaks-profiles/" ; fi
else usage >&2; exit 1; fi
if [ "x$1" = "x-h" ]; then usage >&2; exit 1; fi
if [ "x$1" = "x--help" ]; then usage >&2; exit 1; fi
if [ "$#" -ge 2 ]; then OUTFILE="$2" ;
else                    OUTFILE="$DEFOUTFILE"; fi

OUTPREF="${OUTFILE%.*}"
OUTTYPE="${OUTFILE##*.}"

WDIR="$(realpath "$(dirname "$OUTFILE")")"
mkdir -p "${WDIR}/r_saved_images"

##TODO check if proper OUTTYPE
#OUTTYPE="ipynb"
#OUTTYPE="html"

OUTFIFO="${OUTFILE}.stdout.fifo"

#set -x
#exec 9> >(unbuffer -p tee testsink.log >&2)
#    >(unbuffer -p tee testsink.log >&2) \

[ -p "$OUTFIFO" ] || mkfifo "$OUTFIFO"

MA_WINDOW_SIZE=20

## Warning, '#' inside variables needs to be quoted with '\'
{ cat "$OUTFIFO" >&2 &
"${SCRIPTDIR}/jupyter_execute_notebook.sh" \
  "${NBTOEXEC}" \
  "${OUTPREF}.${OUTTYPE}" \
    "__WD_DIR=${WDIR}" \
    "__STDOUT_FILE=${OUTFIFO}" \
    "__SRC_PARENT_DIR=${SCRIPTDIR}" \
    "__REP_SAMPLE_DIR=${REPSAMPDIR}" \
    "__PROJECT_PREFIX=${OUTPREF}" \
    "__HMAP_PREFIX=${OUTPREF}" \
    "__MA_WINDOW_SIZE=${MA_WINDOW_SIZE}" \
    "__NB_TITLE=${OUTFILE}" \
    "__TEST_VAR=10" \
    "__TEST2_VAR=aaa" 

#  "${OUTPREF}.ipynb" \
## Project dir is set to WDIR inside the notebook
#    "__PROJ_DIR=${WDIR}" \

} && RET="$?" || RET="$?"
[ -p "$OUTFIFO" ] && rm "$OUTFIFO" || true
[ "$RET" -eq 0 ] \
  && echo "Jupyter nbconvert notebook execution run successfully. $NBTOEXEC converted to $OUTFILE" \
  || echo "Jupyter nbconvert notebook execution returned error: $RET while nbconvert-executing $NBTOEXEC"

exit "$RET"


