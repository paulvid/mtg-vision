##################################
# Arguments:                     #
#   $1 _> string to grep for     #
#   $2 _> description of process #
##################################
wait_for_process() {
    grep_string=$1
    process_description=$2

    pids=$(ps -ef | grep "$grep_string" | wc -l)

    while [ $pids -ge 2 ]; do
        i=$(((i + 1) % $MOD))
        printf "\r${SPIN:$i:1} $process_description in progress                           "
        sleep 2
        pids=$(ps -ef | grep "$grep_string" | wc -l)
    done
    printf "\r${CHECK_MARK} $process_description completed                                 "
    echo ""
}

#####################
# Arguments:        #
#   $1 _> retcode   #
#   $2 _> operation #
#   $3 _> error     #
#####################
handle_exception()
{
    if [ "$1" -ne "0" ]; then
        operation=$2
        error=$3
        echo ""
        echo "⛔ error during operation: $operation"
        echo "$error"
        exit $1
    fi
}


export_vars() {
    export SPIN='🌑🌒🌓🌔🌕🌖🌗🌘'
    export MOD=8
    export CHECK_MARK="✅"
    export ALREADY_DONE="❎"

    PYTHONPATH=''
    export PYTHONPATH=$PYTHONPATH:`pwd`:`pwd`/slim
    export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/
    export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/slim
    export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/object_detection
}