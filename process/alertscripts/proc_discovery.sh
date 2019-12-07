#/bin/bash

CONFIG_FILE=/etc/zabbix/proc.conf

check() {
    grep -vE '(^ *#|^$)' ${CONFIG_FILE} | grep -vE '^ *[a-zA-Z]+' &> /dev/null
    if [ $? -eq 0 ]; then
        echo Error: ${CONFIG_FILE} Contains Invalid Proc.
        exit 1
    else
        procarray=($(grep -vE '(^ *#|^$)' ${CONFIG_FILE} | grep -E '^ *[a-zA-Z]+'))
    fi
}

proc_discovery() {
    length=${#procarray[@]}
    printf "{\n"
    printf  '\t'"\"data\":["
    for ((i=0; i<$length; i++)); do
        printf '\n\t\t{'
        printf "\"{#PROC_NAME}\":\"${procarray[$i]}\"}"
        if [ $i -lt $[$length-1] ]; then
            printf ','
        fi
    done
    printf  "\n\t]\n"
    printf "}\n"
}

get_proc() {
    check
    proc_discovery
}

# #### main entrypoint
get_proc

