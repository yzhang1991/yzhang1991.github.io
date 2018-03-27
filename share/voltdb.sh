#!/bin/bash
# Copyright (C) 2013-2018 Yiqun Zhang <zhangyiqun9164@gmail.com>
# All Rights Reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# The default Github path is different on my own macbook and the lab machines.
if [[ $(hostname) =~ Yiquns.+ ]]; then # local macbook
    MACOS=true
    DEFAULT_GITHUB_PATH="/Users/yzhang/Github"
    export PS1='\[\033[1;93m\]\W \u\$ \[\033[0m\]'
elif [[ $(hostname) =~ volt.+ ]]; then # lab machine
    MACOS=false
    DEFAULT_GITHUB_PATH="/tmp/yzhang"
    export PS1='\[\033[1;96m\]\H:\W \u\$ \[\033[0m\]'
else # docker
    MACOS=false
    DEFAULT_GITHUB_PATH="/root"
    export PS1='\[\033[1;95m\]\H:\W \u\$ \[\033[0m\]'
fi

alias ll='ls -lhG'
alias ..='cd ../'        # Go back 1 directory level
alias ...='cd ../../'    # Go back 2 directory levels

if [ -z "$GITHUB_PATH" ]; then
    echo "Setting GITHUB_PATH to $DEFAULT_GITHUB_PATH."
    export GITHUB_PATH="$DEFAULT_GITHUB_PATH"
fi

export PATH="$GITHUB_PATH/voltdb/bin:$PATH"
export CLASSPATH="$CLASSPATH:$GITHUB_PATH/voltdb/voltdb/*"

if [ "$MACOS" == true ]; then
    # export PATH="/usr/local/opt/python@2/libexec/bin:$PATH"
    export ZKLIB=/usr/local/Cellar/kafka/0.10.2.0/libexec/libs
fi

allfuncs=('contains' 'vedit' 'vclone' 'vcheckrepo' 'vfixws' 'cdv' 'cdp' 'cvdb' \
          'vipc' 'vpid' 'kvdb' 'cvoltjar' 'vxml' 'vdb' 'vinitsingle' 'vsingle' \
          'vpull' 'lsb' 'getb' 'cdb' 'rmb' 'mkb' 'vtest')
macfuncs=('vports' 'veclipse' 'vlldb' 'cb' 'jks' 'sshl' 'vmmount' 'cdk' 'kafka')
xml="$GITHUB_PATH/voltdb/deployment.xml"
numberTester='^[0-9]+$'

vhelp() {
    if [ $# -eq 0 ]; then
        for func in ${allfuncs[@]}; do
            $func ?
        done
        if [ "$MACOS" == true ]; then
            for func in ${macfuncs[@]}; do
                $func ?
            done
        fi
    else
        for func in $@; do
            $func ?
        done
    fi
}

printFunctionHelp() {
    local msg=$(printf "$2")
    printf "\033[0;92m%s\033[0m %s\n" "$1" "$msg"
}

contains() {
    local helpmsg="[array] [element]: Test if [array] contains [element]."
    if [ $# -lt 2 ]; then
        printFunctionHelp ${FUNCNAME[0]} "$helpmsg"
        return
    fi

    local target=${!#}
    for ((i=1; i<$#; i++)); do
        if [ "${!i}" == "$target" ]; then
            return 1
        fi
    done
    return 0
}

vclone() {
    local repoName="voltdb"
    if [ $# -eq 1 -a "$1" == "pro" ]; then
        repoName="pro"
    else
        if [ $# -gt 0 ]; then
            local helpmsg="Clone VoltDB repository to designated Github directory.\n%${#FUNCNAME[0]}s Run \"${FUNCNAME[0]} pro\" if you need to clone the pro repository."
            printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
            return
        fi
    fi
    if [ -d $GITHUB_PATH/$repoName ]; then
        echo >&2 "The $repoName repo already exists!"
    else
        mkdir -p $GITHUB_PATH
        pushd $GITHUB_PATH > /dev/null
        git clone https://github.com/VoltDB/$repoName.git
        popd > /dev/null
    fi
}

vcheckrepo() {
    local repoName="voltdb"
    if [ $# -eq 1 -a "$1" == "pro" ]; then
        repoName="pro"
    else
        if [ $# -gt 0 ]; then
            local helpmsg="Check if the specified VoltDB repository exists in the Github directory.\n%${#FUNCNAME[0]}s Run \"${FUNCNAME[0]} pro\" if you need to check the pro repository."
            printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
            return 128
        fi
    fi
    if [ ! -d $GITHUB_PATH/$repoName ]; then
        echo >&2 "The $repoName repo does not exist! Run the vclone command to clone it."
        return 128
    fi
    return 0
}

vfixws() {
    local checkPro=false
    if [ $# -eq 1 -a "$1" == "pro" ]; then
        checkPro=true
    else
        if [ $# -gt 0 ]; then
            local helpmsg="Run licensecheck.\n%${#FUNCNAME[0]}s Use \"${FUNCNAME[0]} pro\" if you need to run with the pro repository."
            printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
            return
        fi
    fi
    # check community repo no matter if "pro" is specified.
    vcheckrepo
    if [ $? -ne 0 ]; then
        return
    fi
    if [ "$checkPro" == true ]; then
        vcheckrepo pro
        if [ $? -ne 0 ]; then
            return
        fi
        pushd $GITHUB_PATH/voltdb > /dev/null
        VOLTPRO=../pro ant licensecheck
    else
        pushd $GITHUB_PATH/voltdb > /dev/null
        ant licensecheck
    fi
    popd > /dev/null
}

cdv() {
    if [ $# -eq 0 ]; then
        vcheckrepo
        if [ $? -eq 0 ]; then
            cd $GITHUB_PATH/voltdb
        fi
    else
        local helpmsg="Get into VoltDB repository."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
    fi
}

cdp() {
    if [ $# -eq 0 ]; then
        vcheckrepo pro
        if [ $? -eq 0 ]; then
            cd $GITHUB_PATH/pro
        fi
    else
        local helpmsg="Get into VoltDB pro repository."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
    fi
}

# edit this file
vedit() {
    if [ $# -gt 0 ]; then
        local helpmsg="Edit this script file."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == true ]; then
        subl $BASH_SOURCE
    else
        vim $BASH_SOURCE
    fi
}

# Compile VoltDB
cvdb() {
    if [ $# -eq 1 -a "$1" == "?" ]; then
        local helpmsg="Compile VoltDB:\n%${#FUNCNAME[0]}s"
        helpmsg="$helpmsg The default build is debug build. Run with \"release\" parameter to do a release build.\n%${#FUNCNAME[0]}s"
        helpmsg="$helpmsg Run with \"trace\" parameter to enable trace.\n%${#FUNCNAME[0]}s"
        helpmsg="$helpmsg Run with \"pro\" parameter to build pro."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    echo "Entering voltdb..."
    pushd $GITHUB_PATH/voltdb > /dev/null
    local build="debug"
    local pro=false
    local flag=""
    for var in "$@"; do
        if [ "$var" == "release" ]; then
            build="release"
        elif [ "$var" == "trace" ]; then
            flag="$flag-DVOLT_LOG_LEVEL=100 "
        elif [ "$var" == "pro" ]; then
            pro=true
        elif [ "$var" == "pool" ]; then
            flag="$flag-DVOLT_POOL_CHECKING=true "
        elif [ "$var" == "verbose" ]; then
            flag="$flag-Dcmake.verbose.build=yes "
        fi
    done
    flag="$flag-Dbuild=$build "

    echo -n "Building VoltDB "
    if [ "$pro" == false ]; then
        echo -n "Community "
    else
        echo -n "Enterprise "
    fi
    echo "edition with $flag"

    if [ "$pro" == false ]; then
        ant -Djmemcheck=NO_MEMCHECK $flag
    else
        VOLTPRO=../pro ant -Djmemcheck=NO_MEMCHECK $flag
    fi
    echo "Returning..."
    popd > /dev/null
}

vipc() {
    if [ $# -eq 1 -a "$1" == "?" ]; then
        local helpmsg="[sitesperhost] [listening port] Run VoltDB IPC with specified [sitesperhost] on [listening port]."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    local ipcpath="$GITHUB_PATH/voltdb/obj/debug/prod/voltdbipc"
    if [ ! -x  $ipcpath ]; then
        echo >&2 "No voltdbipc executable found, do a compile with cvdb."
        return
    fi
    if [ $# -eq 0 ]; then
        $ipcpath 1 10000 &
    elif [ $# -eq 2 ]; then
        $ipcpath $@ &
    fi
}

vpid() {
    if [ $# -ne 0 ]; then
        local helpmsg="Show the process IDs of VoltDB."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    for pid in `ps aux | grep org.voltdb.VoltDB | grep -v grep | tr -s ' ' | cut -f2 -d' '`; do
        echo "$pid"
    done
}

vlldb() {
    if [ $# -ne 0 ]; then
        local helpmsg="Run LLDB and attach to the VoltDB process."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == false ]; then
        echo >&2 "This command can only be used under OS X."
        return
    fi
    pid=`vpid`
    if [ "$pid" == "" ]; then
        >&2 echo "VoltDB is not running, start VoltDB first."
        return
    fi
    lldb -p `vpid` -o "pro hand -s false -n false SIGBUS"
}

# Kill VoltDB instances
kvdb() {
    if [ $# -ne 0 ]; then
        local helpmsg="Kill VoltDB processes."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    for pid in `ps aux | grep org.voltdb.VoltDB | grep -v grep | tr -s ' ' | cut -f2 -d' '`; do
        kill -9 $pid
        echo "Killed VoltDB instance $pid."
    done
    rm -f $xml > /dev/null 2>&1
}

# Compile VoltDB stored procedures
cvoltjar() {
    if [ $# -eq 1 -a ! "$1" == "?" ]; then
        javac -cp "$CLASSPATH:$GITHUB_PATH/voltdb/voltdb/*:$GITHUB_PATH/voltdb/lib/extension/*" *.java
        jar cvf $1.jar *.class
        rm *.class
    else
        local helpmsg="[jar name]: Compile all the java files in the current workspace into [jar name].jar"
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
    fi
}

vxml() {
    # [host count] [site per host] [k factor]
    local hc=1
    local sph=8
    if [ "$1" == "?" ]; then
        local helpmsg="[host count] [site per host] [k factor]: Create deployment file in default location using the specified parameters."
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s Default hostcount=1, sitesperhost=8, kfactor=0;"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s Defaults are used when not enoough parameters are specified."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ $# -ge 1 ]; then
        hc=$1
    fi
    local kfactor=$(echo "$hc-1" | bc)
    if [ $# -ge 2 ]; then
        sph=$2
    fi
    if [ $# -ge 3 ]; then
        kfactor=$3
    fi
    printf "hostcount=%s, sitesperhost=%s, kfactor=%s\n" $hc $sph $kfactor
    echo "<deployment>" > $xml
    echo "<cluster hostcount=\"$hc\" sitesperhost=\"$sph\" kfactor=\"$kfactor\" />" >> $xml
    echo "</deployment>" >> $xml
}


vdb() {
    if [ "$1" == "?" ]; then
        local helpmsg="[host count] [site per host] [k factor]: Start VoltDB with specified parameters"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s Default hostcount=1, sitesperhost=8, kfactor=0;"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s Defaults are used when not enoough parameters are specified."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    local pids=$(vpid)
    if [ ! "$pids" == "" ]; then
        echo -ne "It seems like VoltDB is already running on this machine, kill it first? [\033[0;93mY\033[0m/n] "
        read -n 1 ans
        echo ""
        if [ "$ans" != "n" ]; then
            kvdb
        fi
    fi
    vxml $@
    local hc=1
    if [ $# -ge 1 ]; then
        hc=$1
    fi
    local kfactor=$(echo "$hc-1" | bc)

    rm -rf $GITHUB_PATH/voltdb/node*
    echo "Initializing VoltDB root directories..."
    for ((i=1; i<=hc; i++)); do
        vinitsingle $i
    done
    echo "Starting VoltDB processes..."
    for ((i=1; i<=hc; i++)); do
        vsingle $hc $i
    done
}

vinitsingle() {
    if [ "$1" == "?" ]; then
        local helpmsg="[node ID] Initialize the VoltDB root directory for the [node ID]-th node in a cluster."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    voltdb init --force -D $GITHUB_PATH/voltdb/node$1 -C $xml
}

vports() {
    if [ $# -ne 1 -o "$1" == "?" ]; then
        local helpmsg="[node ID] Show the VoltDB port parameters for the [node ID]-th node."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == false ]; then
        echo >&2 "This command can only be used under OS X."
        return
    fi
    printf '%sadmin=%s --client=%s --http=%s --internal=%s --zookeeper=%s' '--' \
           $(echo "21211-$1+1" | bc) $(echo "21212+$1-1" | bc) $(echo "8080+$1-1" | bc) \
           $(echo "3021+$1-1" | bc) $(echo "7181+$1-1" | bc) | tee /dev/tty | pbcopy
    echo -e "\n\nCommand copied to clipboard."
}

veclipse() {
    if [ $# -ne 2 ]; then
        local helpmsg="[host count] [node ID]: Get the command to start the [node ID]-th node in a [host count]-node cluster in Eclipse."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == false ]; then
        echo >&2 "This command can only be used under OS X."
        return
    fi
    echo "To run in Eclipse, use:"
    echo -n "license \"\${workspace_loc}/voltdb/voltdb/license.xml\" voltdbroot \"\${workspace_loc}/voltdb/node$2\" probe placementgroup 0 mesh localhost hostcount $1" | tee /dev/tty | pbcopy
    echo -e "\n\nCommand copied to clipboard."
}

vsingle() {
    if [ $# -ne 2 ]; then
        local helpmsg="[host count] [node ID]: Start the [node ID]-th node in a [host count]-node cluster."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    voltdb start -c $1 -H localhost:3021 -D $GITHUB_PATH/voltdb/node$2 \
                 --admin=$(echo "21211-$2+1" | bc) \
                 --client=$(echo "21212+$2-1" | bc) \
                 --http=$(echo "8080+$2-1" | bc) \
                 --internal=$(echo "3021+$2-1" | bc) \
                 --zookeeper=$(echo "7181+$2-1" | bc) &
}

vpull() {
    if [ $# -ne 0 ]; then
        local helpmsg="Do a git pull on VoltDB repositories."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ -d $GITHUB_PATH/voltdb ]; then
        pushd $GITHUB_PATH/voltdb > /dev/null
        git pull
        popd > /dev/null
    fi
    if [ -d $GITHUB_PATH/pro ]; then
        pushd $GITHUB_PATH/pro > /dev/null
        git pull
        popd > /dev/null
    fi
}

lsb() {
    if [ $# -ne 0 ]; then
        local helpmsg="List all the branches in the VoltDB repository."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    vcheckrepo
    if [ $? -ne 0 ]; then
        return
    fi
    pushd $GITHUB_PATH/voltdb > /dev/null
    local branches="$(git branch)"
    popd > /dev/null
    if [ $? -eq 0 ]; then
        local cnt=1
        local curr=$(echo "$branches" | grep "*" | sed "s/[* ]//g")
        echo -e "Current branch: \033[0;92m$curr\033[0m"
        echo "Branches available:"
        for b in $(echo "$branches" | sed "s/[* ]//g"); do
            echo "  $cnt  $b"
            let cnt=cnt+1
        done
        return 0
    else
        return 128
    fi
}

# Get the branch with specified branch number in lsb()
getb() {
    if [ $# -ne 1 -o "$1" == "?" ]; then
        local helpmsg="[branch number]: Get the VoltDB branch numbered [branch number] in the lsb output."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return 128
    fi

    local branches=$(lsb | sed '1,2d')
    if [ $? -eq 0 ]; then
        local cnt=`echo "$branches" | wc -l`
        if [ $1 -gt $cnt ] || [ $1 -le 0 ]; then
            >&2 echo "Invalid branch number."
        else
            local branch=`echo "$branches" | sed -n ${1}p | cut -d' ' -f5`
            echo "$branch"
            return 0
        fi
    fi
    return 128
}

cb() {
    if [ $# -gt 1 -o "$1" == "?" ]; then
        local helpmsg="[branch number]: Copy the VoltDB branch numbered [branch number] in the lsb output."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == false ]; then
        echo >&2 "This command can only be used under OS X."
        return
    fi
    local num=$1
    if [ $# -eq 0 ]; then
        lsb
        echo -ne "Select a branch number to copy its branch name: \033[0;93m"
        read num
        echo -ne "\033[0m"
    fi
    local bname=$(getb $num)
    if [ $? -eq 0 ]; then
        echo -n "$bname" | pbcopy
        echo -e "Copied to clipboard: \033[0;92m$bname\033[0m"
    fi
}

# Format the branch name, if a number is given then convert it to full branch name.
formatBranchName() {
    if [ $# -eq 0 ]; then
        >&2 echo "Branch name not specified."
    else
        if [[ $1 =~ $numberTester ]]; then
            formattedName=`getb $1`
            if [ $? -ne 0 ]; then
                return 128
            fi
            echo "$formattedName"
        else
            echo $1
        fi
    fi
}

# checkout VoltDB branch
cdb() {
    if [ $# -gt 1 -o "$1" == "?" ]; then
        local helpmsg="[branch number | branch name]: Checkout a VoltDB branch either --"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s numbered [branch number] in the lsb output, or:"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s named [branch name]"
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return 0
    fi
    local num=$1
    if [ $# -eq 0 ]; then
        lsb
        echo -ne "Select a branch number to enter: \033[0;93m"
        read num
        echo -ne "\033[0m"
    fi
    branch=$(formatBranchName $num)
    if [ $? -ne 0 ]; then
        echo >&2 "Invalid selection."
        return 128
    fi
    echo "Checkout branch $branch."
    if [ -d $GITHUB_PATH/voltdb ]; then
        pushd $GITHUB_PATH/voltdb > /dev/null
        git checkout $branch
        local ret=$?
        popd > /dev/null
        if [ $ret -ne 0 ]; then
            return 128
        fi
    fi
    if [ -d $GITHUB_PATH/pro ]; then
        pushd $GITHUB_PATH/pro > /dev/null
        git checkout $branch
        local ret=$?
        popd > /dev/null
        if [ $ret -ne 0 ]; then
            return 128
        fi
    fi
    return 0
}

# Remove VoltDB branch
rmb() {
    if [ $# -gt 1 -o "$1" == "?" ]; then
        local helpmsg="[branch number | branch name]: Remove a VoltDB branch either --"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s numbered [branch number] in the lsb output, or:"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s named [branch name]"
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    local num=$1
    if [ $# -eq 0 ]; then
        lsb
        echo -ne "Select a branch number to remove: \033[0;93m"
        read num
        echo -ne "\033[0m"
    fi
    branch=`formatBranchName $num`
    if [ $? -ne 0 ]; then
        echo >&2 "Invalid selection."
        return
    fi
    if [ "$branch" == "master" ]; then
        >&2 echo "Cannot remove the master branch."
        return
    fi
    local ans=""
    echo -ne "Remove branch $branch? [\033[0;93mY\033[0m/n]: "
    read -n 1 ans
    echo ""
    if [ "$ans" == "n" ]; then
        echo "Canceled."
        return
    fi
    echo "Removing branch $branch."
    if [ -d $GITHUB_PATH/voltdb ]; then
        pushd $GITHUB_PATH/voltdb > /dev/null
        git checkout master
        git branch -D $branch
        if [ $? -ne 0 ]; then
            return
        fi
        echo -ne "Remove origin/$branch? [y/\033[0;93mN\033[0m]: "
        read -n 1 ans
        echo ""
        if [ "$ans" == "y" ]; then
            git push -d origin $branch
        fi
        popd > /dev/null
    fi
    
    if [ -d $GITHUB_PATH/pro ]; then
        pushd $GITHUB_PATH/pro > /dev/null
        git checkout master
        git branch -D $branch
        if [ $? -ne 0 ]; then
            return
        fi
        echo -ne "Remove origin/$branch? [y/\033[0;93mN\033[0m]: "
        read -n 1 ans
        echo ""
        if [ "$ans" == "y" ]; then
            git push -d origin $branch
        fi
        popd > /dev/null
    fi
}

# Create VoltDB branch
mkb() {
    if [ $# -ne 1 -o "$1" == "?" ]; then
        local helpmsg="[branch name]: Create a VoltDB branch named [branch name]"
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ $# -eq 0 ]; then
        >&2 echo "Branch name not specified."
        return
    fi
    local ans=""
    if [ "${1:0:4}" != "ENG-" ]; then
        echo -ne "Branch name does not start with \"ENG-\", continue? [\033[0;93mY\033[0m/n]: "
        read -n 1 ans
        echo ""
        if [ "$ans" == "n" ]; then
            return
        fi
    fi

    local switchMaster=true
    if [ -d $GITHUB_PATH/voltdb ]; then
        pushd $GITHUB_PATH/voltdb > /dev/null
        branches="`git branch`"
        curr=$(echo "$branches" | grep "*" | sed "s/[* ]//g")
        if [[ "$curr" != "master" ]]; then
            echo -ne "The current branch is not master, switch to master then make the new branch? [\033[0;93mY\033[0m/n]: "
            read -n 1 ans
            echo ""
            if [[ "$ans" == "y" ]]; then
                cdb master
                if [ $? -ne 0 ]; then
                    return
                fi
            else
                switchMaster=false
            fi
        fi

        git checkout -b $1
        if [ $? -ne 0 ]; then
            return
        fi
        git push origin head
        git branch --set-upstream-to=origin/$1 $1
        popd > /dev/null
    fi

    if [ -d $GITHUB_PATH/pro ]; then
        pushd $GITHUB_PATH/pro > /dev/null
        branches="`git branch`"
        curr=$(echo "$branches" | grep "*" | sed "s/[* ]//g")
        if [[ "$curr" != "master" ]]; then
            if [ "$switchMaster" == true ]; then
                cdb master
                if [ $? -ne 0 ]; then
                    return
                fi
            fi
        fi

        git checkout -b $1
        if [ $? -ne 0 ]; then
            return
        fi
        git push origin head
        git branch --set-upstream-to=origin/$1 $1
        popd > /dev/null
    fi
}

jks() {
    if [ $# -gt 1 -o "$1" == "?" ]; then
        local helpmsg="[branch number | branch name]: Go to the Jenkins page for either --"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s numbered [branch number] in the lsb output, or:"
        helpmsg="$helpmsg\n%${#FUNCNAME[0]}s named [branch name]"
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == false ]; then
        echo >&2 "This command can only be used under OS X."
        return
    fi
    local num=$1
    if [ $# -eq 0 ]; then
        lsb
        echo -ne "Select a branch number to enter Jenkins: \033[0;93m"
        read num
        echo -ne "\033[0m"
    fi
    branch=$(formatBranchName $num)
    if [ $? -ne 0 ]; then
        echo >&2 "Invalid selection."
        return
    fi
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "http://ci.voltdb.lan/view/Branch-jobs/view/branch-$branch" > /dev/null 2>&1
}

# Run VoltDB jUnit test
vtest() {
    if [ "$1" == "?" ]; then
        local helpmsg="[junit test name]: Run VoltDB junit test [junit test name]."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ ! -d $GITHUB_PATH/voltdb ]; then
        return
    fi
    local testname=$1
    if [ $# -eq 0 ]; then
        if [ ! -f ~/.vtest_history ]; then
            vtest ?
            return
        fi
        testname=$(cat ~/.vtest_history)
        echo "Run most recent test $testname..."
    fi
    pushd $GITHUB_PATH/voltdb > /dev/null
    ant junitclass -Djunitclass=$testname -Dbuild=debug
    echo -n "$testname" > ~/.vtest_history
    popd > /dev/null
}

sshl() {
    if [ $# -ne 1 -o "$1" == "?" ]; then
        local helpmsg="[lab machine number]: Connect to volt[lab machine number].voltdb.lan."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    ssh yiqun@volt$1.voltdb.lan
}

vmmount() {
    if [ $# -eq 1 -a "$1" != "?" ]; then
        if [ "$MACOS" == false ]; then
            echo >&2 "This command can only be used under OS X."
            return
        fi
        if [ ! -d $HOME/share ]; then
            mkdir -p $HOME/share
        fi
        sudo mount -t vboxsf -o rw,uid=1000,gid=1000 $1 $HOME/share
    else
        local helpmsg="[shared folder name]: Mount VirtualBox shared folder [shared folder name] to $HOME/share."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
    fi
}

cdk() {
    if [ $# -gt 0 ]; then
        local helpmsg="Enter Kafka executives folder."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == false ]; then
        echo >&2 "This command can only be used under OS X."
        return
    fi
    local kpath="/usr/local/Cellar/kafka/0.10.2.0/bin"
    if [ ! -d $kpath ]; then
        echo >&2 "Kafka installation path does not exist."
        echo >&2 "  ($kpath)"
    else
        cd $kpath
    fi
}

kafka() {
    if [ $# -gt 0 ]; then
        local helpmsg="Run Kafka server."
        printFunctionHelp "${FUNCNAME[0]}" "$helpmsg"
        return
    fi
    if [ "$MACOS" == false ]; then
        echo >&2 "This command can only be used under OS X."
        return
    fi
    echo "Start ZooKeeper server:"
    zookeeper-server-start /usr/local/etc/kafka/zookeeper.properties &
    echo "Start Kafka server:"
    kafka-server-start /usr/local/etc/kafka/server.properties
}

# kcreate() {
#     if [ $# -ne 1 ]; then
#         >&2 echo "Create kafka topic: kcreate [topic name]"
#         return
#     fi
#     kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic $1
# }

# kdel() {
#     if [ $# -ne 1 ]; then
#         >&2 echo "Delete kafka topic: kdel [topic name]"
#         return
#     fi
#     kafka-topics --delete --zookeeper localhost:2181 --topic $1
# }

# kdescribe() {
#     if [ $# -ne 1 ]; then
#         >&2 echo "Describe kafka topic: kdescribe [topic name]"
#         return
#     fi
#     kafka-topics --zookeeper localhost:2181 --describe --topic $1
# }

# kls() {
#     kafka-topics --list --zookeeper localhost:2181
# }

# kconsume() {
#     if [ $# -ne 1 ]; then
#         >&2 echo "Consume kafka topic: kconsume [topic name]"
#         return
#     fi
#     kafka-console-consumer --zookeeper localhost:2181 --topic $1
# }

# kproduce() {
#     if [ $# -ne 1 ]; then
#         >&2 echo "Produce to kafka topic: kproduce [topic name]"
#         return
#     fi
#     kafka-console-producer --broker-list localhost:9092 -topic $1
# }

# vctest() {
#     if [ $# -eq 0 ]; then
#         >&2 echo "C++ unit test name not specified."
#         >&2 echo "If you want to run all the C++ unit tests, run \"ant clean eecheck\"."
#         return
#     fi
#     src=`find $GITHUB_PATH/voltdb/tests/ee -name "$1.cpp"`
#     if [ "$src" == "" ]; then
#         >&2 echo "Cannot find the source file for test $1."
#         return
#     fi
#     if [ ! -d $GITHUB_PATH/voltdb/obj/debug ]; then
#         echo "$GITHUB_PATH/voltdb/obj/debug does not exist, do a full eecheck build."
#         ant clean eecheck -Dbuild=debug
#     else
#         echo "Re-compile $1:"
#         pushd $GITHUB_PATH/voltdb/obj/debug > /dev/null
#         rm cpptests/$1 2> /dev/null
#         if [[ "$OSTYPE" == "linux-gnu" ]]; then
#             osflags=" -Wno-attributes -Wcast-align -DLINUX -fpic"
#         elif [[ "$OSTYPE" =~ darwin[0-9]+ ]]; then
#             osflags=" -DMACOSX -arch x86_64"
#         fi
#         cmd="g++  -Wall -Wextra -Werror -Woverloaded-virtual -Wpointer-arith -Wcast-qual -Wwrite-strings
#              -Winit-self -Wno-sign-compare -Wno-unused-parameter -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS
#              -DNOCLOCK -fno-omit-frame-pointer -fvisibility=default -DBOOST_SP_DISABLE_THREADS
#              -DBOOST_DISABLE_THREADS -DBOOST_ALL_NO_LIB -Wno-unused-local-typedefs -Wno-absolute-value
#              -Wno-ignored-qualifiers -fno-strict-aliasing -std=c++11 -g3 -O0 -DDEBUG -DVOLT_LOG_LEVEL=500
#              $osflags -isystem $GITHUB_PATH/voltdb/third_party/cpp -I$GITHUB_PATH/voltdb/src/ee
#              -I$GITHUB_PATH/voltdb/obj/debug/3pty-install/include -I$GITHUB_PATH/voltdb/obj/debug  -c
#              -I$GITHUB_PATH/voltdb/tests/ee -MMD -MP -o static_objects/$1.o $src"
#         echo $cmd
#         $cmd
#         cmd="g++  -Wall -Wextra -Werror -Woverloaded-virtual -Wpointer-arith -Wcast-qual -Wwrite-strings
#              -Winit-self -Wno-sign-compare -Wno-unused-parameter -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS
#              -DNOCLOCK -fno-omit-frame-pointer -fvisibility=default -DBOOST_SP_DISABLE_THREADS
#              -DBOOST_DISABLE_THREADS -DBOOST_ALL_NO_LIB -Wno-unused-local-typedefs -Wno-absolute-value
#              -Wno-ignored-qualifiers -fno-strict-aliasing -std=c++11 -g3 -O0 -DDEBUG -DVOLT_LOG_LEVEL=500
#              $osflags -isystem $GITHUB_PATH/voltdb/third_party/cpp -I$GITHUB_PATH/voltdb/src/ee
#              -I$GITHUB_PATH/voltdb/obj/debug/3pty-install/include -I$GITHUB_PATH/voltdb/obj/debug
#              -L$GITHUB_PATH/voltdb/obj/debug/3pty-install/lib -g3  -o cpptests/$1 static_objects/$1.o
#              objects/harness.o objects/volt.a  -lpcre2-8 -ls2geo -lcrypto"
#         echo $cmd
#         $cmd
#         echo -e "\nRun cpptests/$1:"
#         cpptests/$1
#         popd > /dev/null
#     fi
# }

# vh1() {
#     echo "Entering voltdb..."
#     pushd $GITHUB_PATH/voltdb > /dev/null
#     ant -Djunit.timeout=720000 -Dverifycatalogdebug=true clean default killstragglers junit_regression_h1
#     echo "Returning..."
#     popd > /dev/null
# }

# # Run voltdb mem test
# vmem() {
#     echo "Entering voltdb..."
#     cd $GITHUB_PATH/voltdb
#     if [ $# -eq 0 ]; then
#         VOLTPRO=../pro ant -Dbuild=memcheck -Djmemcheck=NO_MEMCHECK clean default voltdbipc
#         mv obj/release obj/memcheck
#     else
#         VOLTPRO=../pro ant -Dbuild=memcheck -Djmemcheck=NO_MEMCHECK -DVOLT_REGRESSIONS=local -Dverifycatalogdebug=false -Djunitclass=$1 killstragglers junitclass
#     fi
# }

# codeindex() {
#     pushd /usr/local/opengrok/bin > /dev/null
#     IGNORE_PATTERNS="-i d:obj -i *.jar" OpenGrok index $GITHUB_PATH
#     popd > /dev/null
# }

# vcleanup() {
#     cppclean --include-path $GITHUB_PATH/voltdb/third_party/cpp --include-path $GITHUB_PATH/voltdb/src/ee --include-path $GITHUB_PATH/voltdb/obj/release/3pty-install/include --include-path $GITHUB_PATH/voltdb/obj/release $GITHUB_PATH/voltdb/src/ee
# }
