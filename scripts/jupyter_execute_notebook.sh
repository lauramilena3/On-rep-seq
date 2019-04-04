#!/bin/bash
## Maciek Sykulski <macieksk@gmail.com>, 2019
set -eu

JUPLOGLVL="DEBUG"
JUPLOGLVL="INFO"
TIMEOUT=30 ## Cell execution timeout

set -x
IPYNB="$1"; IPYNBOUT="$2"; shift 2
set +x
extension="${IPYNBOUT##*.}"
OUTTYPE="$extension"
#OUTTYPE="ipynb"
#OUTTYPE="html"
if [ "$OUTTYPE" = "ipynb" ]; then OUTTYPE="notebook"; fi

#SINK="$1"; shift 1
#exec 3> >(unbuffer -p tee testsink.log >&2)
#echo "SFDAF" >> "$SINK"
#set -- "__STDOUT_FILE=$SINK" "$@"
#IPYNBOUT="$PWD/$(basename "$IPYNB" .ipynb).execution_result.${OUTTYPE}"

SEDCMD="$(parallel --halt never -k --colsep '=' \
  'if [ -n "{2}" ]; then echo "s#{1}#{2}#g"; \
   else echo "!!! Warning, couldn'\''t parse argument {}" >&2; fi' \
   ::: "$@" | paste -sd ';')"

set -x
jupyter nbconvert --to notebook \
    --log-level="$JUPLOGLVL" \
    --execute <(set -eux; < "$IPYNB" sed "$SEDCMD") \
    --output "$IPYNBOUT" \
    --output-dir "$(dirname "$IPYNBOUT")" \
    --ExecutePreprocessor.timeout="$TIMEOUT" \
    --ExecutePreprocessor.interrupt_on_timeout=True \
    --to="$OUTTYPE" \
    --allow-errors \

#    --save-on-error \## Not yet implemented in jupyter/nbconvert

    #--stdout
    #"$@"
#    --execute <(< "$IPYNB" sed 's/exponent=2/exponent=5/') \
#    --output "$(pwd)/Power_Function_output.ipynb"


