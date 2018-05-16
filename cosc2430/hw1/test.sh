filename="densemult"
casecount=3
timeout="10s"

checkIfFileExists() {
    if [ $# -eq 1 ]; then
        echo -n "$1 "
        if ! [ -f $1 ]; then
            echo -e "\033[1;91mFAIL\033[0m"
            exit
        else
            echo -e "\033[0;92mOK\033[0m"
        fi
    fi
}

echo "Checking workspace..."
checkIfFileExists "Makefile"
checkIfFileExists "$filename.cpp"
echo "Test cases..."
for casenum in `seq 1 1 $casecount`; do
    checkIfFileExists "$casenum.txt"
    checkIfFileExists "$casenum.ans"
done

echo "Compiling..."
make clean
make

echo "Testing..."
echo -e "Program name is \033[1;93m$filename\033[0m."
for casenum in `seq 1 1 $casecount`; do
    echo -e "\033[1;93mTest case $casenum\033[0m"
    timeout -k $timeout $timeout ./$filename "A=$casenum.txt;C=$casenum.out" 1>$casenum.stdout 2>$casenum.stderr 
    if [ $? -ne 0 ]; then
        echo -e "    \033[1;91mProgram killed due to timeout ($timeout).\033[0m"
        echo "Test case $casenum timed out ($timeout)." >> TIMEOUT
    fi
    diff -iEBwu $casenum.ans $casenum.out > $casenum.diff
    if [ $? -ne 0 ]; then
        echo -e "    \033[1;91mFAILED.\033[0m"
    else
        echo -e "    \033[1;92mPASSED.\033[0m"
        rm -f $casenum.diff
    fi
done

