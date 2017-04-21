#!/bin/bash
#
# Author: Gabriele Zappi (Gabolander developer) <gabodevelop@gmail.com>
#
# Release date: 2017 April 21st
# 
# See README and LICENSE for more details.

# BASE (CUSTOM) VARIABLES - They may vary depending on system environment
LIBSTDC_PATH=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
SDK_HOME=/opt/Android/Sdk
EMULATOR_PATH=${SDK_HOME}/emulator/emulator
ADB_PATH=${SDK_HOME}/platform-tools/adb
WRITABLE="-writable-system"

# LANG="it_IT.UTF-8"
# export LANG
LC_ALL=C
export LC_ALL

PRG=`basename $0`
PRGBASE=`basename $0 .sh`
PRGDIR=`dirname $0`
VERSION="0.90.0"
LAST_UPD="20-04-2017"

ACTDIR=`pwd`
OGGI=`date +%Y%m%d`
OGGI_ITA=`date +%d-%m-%Y`
ORA_ITA=`date +%H:%M:%S`
if [ -z "$HOSTNAME" ]; then
  HOSTNAME=`hostname`
fi
TMPDIR=`mktemp -d /tmp/${PRGBASE}_temp_dir_XXXXX`
TMP1="$TMPDIR/${PRGBASE}-1_temp"
TMP2="$TMPDIR/${PRGBASE}-2_temp"
TMP3="$TMPDIR/${PRGBASE}-2_temp"
TEMPORANEI="$TMPDIR"

## Log
LOGDIR="/var/log"
LOGFILE="${LOGDIR}/${PRGBASE}.log"
LOGFILEXT="${LOGDIR}/${PRGBASE}-ext-${OGGI}.log"


# declare -a sms_errors=('child procs already',"lerrore di stocazzo")  #Per ora solo uno

### Comandi
TAR=`which tar`
GREP=`which grep`
WC=`which wc`
CAT=`which cat`
SSH=`which ssh`
SCP=`which scp`
SORT=`which sort`
UNIQ=`which uniq`
FDUPES=`which fdupes`
RSYNC=`which rsync`
EXIFTOOL=`which exiftool`
DIALOG=`which dialog`
WHIPTAIL=`which whiptail`

######
# Libreria funzioni
if [ -f "$PRGDIR/bash_functions_lib.inc.sh" ]; then
  . "$PRGDIR/bash_functions_lib.inc.sh"
fi

####
#  Funzioni
#
function is_number() {
	VARIABLE=$1
	if [ $VARIABLE -eq $VARIABLE 2> /dev/null ]; then
		# echo $VARIABLE is a number
		isnumber=YES
	else
		isnumber=NO
	fi
}

function at_exit()
{
  if [ "$1" -gt 0 -a "$1" -lt 32 ]; then
    echo -n "Uscita irregolare per : "
  else
#     echo "Uscita regolare." # debug
      echo
  fi 
      
  case "$1" in
     1) 
      echo "SIGHUP    /* Hangup (POSIX).  */"
      ;;
     2) echo "SIGINT    /* Interrupt (ANSI).  */"
      ;;
     3) echo "SIGQUIT   /* Quit (POSIX).  */"
      ;;
     9) echo "SIGKILL   /* Kill, unblockable (POSIX).  */"
      ;;
     12) echo "SIGUSR2     /* User-defined signal 2 (POSIX).  */"
      ;;
     13) echo "SIGPIPE     /* Broken pipe (POSIX).  */"
      ;;
     15) echo "SIGTERM     /* Termination (ANSI).  */"
      ;;
  esac

  rm -rf "$TEMPORANEI"

  # Clear screen before exit?
  # clear

  exit $1
}

sino()
{
  SINO=""
  DEF=""
  TMP=""
  MSG=`echo "$1" | cut -c1`
  if [ "$MSG" = "-" ]; then
    MSG=""
  else
    MSG="$1"
  fi

  if [ -z "$2" ]; then
    TMP="$1"
  else
    TMP="$2"
  fi
  TMP=`echo $TMP | tr [:lower:] [:upper:]`
  DEF=`echo $TMP | cut -c1`
  if [ -n "$MSG" -a -n "$DEF" ]; then
	MSG="$MSG [def=$DEF]"
  fi

  while [ "$SINO" != "S" -a  "$SINO" != "N" ]; do
    echo -n "$MSG :"
    read SINO
    [ -z "$SINO" ] && SINO=$DEF
    SINO=`echo $SINO | tr [:lower:] [:upper:]`
    if [ "$SINO" != "S" -a  "$SINO" != "N" ]; then
	echo "Prego rispondere con S o N."
    fi
  done
}

proseguo()
{
  RISP=""
  while [ "$RISP" != "S" ]; do
    echo -ne "\n Proseguo ('S' per Si, CTRL+C per interrompere) : "
    read RISP
#   RISP=`echo $RISP | tr [:lower:] [:upper:]`
  done
}

pinvio()
{
  echo -ne "\n Premere [INVIO] per continuare. "
  read RISP
  echo " "
}



function agg_ora()
{
  OGGI=`date +%Y%m%d`
  OGGI_ITA=`date +%d-%m-%Y`
  ORA_ITA=`date +%H:%M:%S`
  DATAIERI=`date -d yesterday +%Y%m%d`
}

function help()
{
  cat<<!EOM
 Uso $PRG : 
     $PRG <parametri>
          parametri:
          -h | --help  =  Questo help
          -q | --quiet = Non vengono inviati messaggi di stato in output,
                         ma viene scritto solo il log in $LOGFILE
!EOM
  at_exit 0
}

function logga()
{
	[ -n "$QUIET" ] || echo "$1"
	echo "$1" >> $LOGFILE
	[ -z "$DEBUG" ] || echo "$1" >> $LOGFILEXT
}


function valuta_parametri() {
#!/bin/sh
# scansione_1.sh

# Si raccoglie la stringa generata da getopt.
# STRINGA_ARGOMENTI=`getopt -o aB:c:: -l a-lunga,b-lunga:,c-lunga:: -- "$@"`
STRINGA_ARGOMENTI=`getopt -o hB:Sfy -l help,repo-dir:,repobase-directory:,simulate,fdupes,yes -- "$@"`


# Inizializzazione parametri di default
REPOBASE_DIR=""
SIMULATE=""
USE_FDUPES=""
ANS_YES=""

# Si trasferisce nei parametri $1, $2,...
eval set -- "$STRINGA_ARGOMENTI"

while true ; do
#		echo "Param = $1" # debug
    case "$1" in
#        -a|--a-lunga)
#            echo "Opzione a" # debug
#            shift
#            ;;
	-h|--help)
			shift
			help
			;;
	-f|--fdupes)
			shift
			USE_FDUPES="yes"
			;;
	-y|--yes)
			shift
			ANS_YES="yes"
			;;
        -B|--repo-dir*|--repobase-dir*)
            # echo "Opzione b, argomento «$2»" # debug
						[ -z "$2" ] && at_exit 99
						REPOBASE_DIR="$2"
            shift 2
            ;;
#        -c|--c-lunga)
#            case "$2" in
#                "") echo "Opzione c, senza argomenti" # debug
#                    shift 2
#                    ;;
#                *)  echo "Opzione c, argomento «$2»" # debug
#                    shift 2
#                    ;;
#            esac
#            ;;
				-S|--simulate) 
						SIMULATE="S"
						shift
						;;
				-N|--no-delete-user*)
						NODELUSER="S"
						shift
						;;
        --) shift
            break
            ;;
        *)  echo "Errore imprevisto!"
            exit 1
            ;;
        esac
done

ARG_RESTANTI=()
for i in `seq 1 $#`
do
    eval a=\$$i
#    echo "$i) $a"
    ARG_RESTANTI[$i]="$a"
done


#### [ "${#ARG_RESTANTI[*]}" -eq 0 ] && help "$PRG: ${COL_LTRED}ERRORE${COL_RESET}: pochi parametri!\n" 99

}


function infobox() {
	if [ -n "$DIALOG" ]; then
		# For infobox option, I use 'dialog' anyway because of a bug of whiptail !!
		$DIALOG --infobox "$1" 15 50
	else
		echo "- $1"
	fi
}

function show_error() {
	if [ -n "$TUI" ]; then
		$DIALOG --title "Error" --msgbox "$1" 15 60
	else
		echo "ERROR: $1"
	fi
}



#############################################################
# INIZIO SCRIPT                                             #
#############################################################

# Trappiamo i segnali
for ac_signal in 1 2 13 15; do
  trap 'ac_signal='$ac_signal'; at_exit $ac_signal;' $ac_signal
done
ac_signal=0


#-- Valutazione dei parametri (argomenti - e --) e elborazione restanti - inizio
# come da script "rsync_dedup_repo.sh"
valuta_parametri "$@"
newparams=""
for i in `seq 1 ${#ARG_RESTANTI[*]}`
do
 newparams="$newparams '${ARG_RESTANTI[$i]}'"
# echo "Ciclo $i) ARG_RESTANTI[$i] = ${ARG_RESTANTI[$i]} "
done
#echo "\$newparams = $newparams"

# set -- "${ARG_RESTANTI[*]}"
# set -- "$(for i in `seq 1 ${#ARG_RESTANTI[*]}`;do echo "${ARG_RESTANTI[$i]}"; done)"
eval "set -- $newparams"
# Ora li valuto normalmente come $1, $2, ... $n

### Da usare nel caso si vogliano imporre argomenti
# if [ -z "$1" ]; then
#	echo "$PRG: No argomenti?"
#	at_exit 99
#fi
#-- Valutazione dei parametri (argomenti - e --) e elborazione restanti - fine

## sino "Proseguo con l'elaborazione?" "N"
## if [ $SINO = "S" ]; then
## :
## else
## at_exit 99
## fi
## echo

# Look for what TUI to use
TUI=""
if [ -n "$WHIPTAIL" ]; then
	TUI=$WHIPTAIL
elif [ -n "$DIALOG" ]; then
	TUI=$DIALOG
fi

# DEBUG
# TUI= ... (TUI="" | TUI=$DIALOG | TUI=$WHIPTAIL)
# TUI=""

clear

$ADB_PATH devices | grep -v -e "List of dev" -e "^$" | grep "^emulator-" > $TMP1

# DEBUG - Alter tmp with a custom (fake) list
# TMP1=/tmp/a

nl=`$CAT $TMP1 | $WC -l`


if [ "$nl" -eq 0 ]; then
	if [ -n "$TUI" ]; then
		$TUI --msgbox "No running AVD found. Please lunch at least one x86 AVD to install Google Play onto." 10 60
	else
		echo "No running AVD found. Please lunch at least one x86 AVD to install Google Play onto."
	fi
	at_exit -1
fi

# /opt/Android/Sdk/platform-tools/adb devices | grep -v -e "List of dev" -e "^$"
declare -a avds
cnt=0
while read line
do
	avds[$((cnt++))]=$line
done < $TMP1

SERIAL_OPTION=""
if [ "$nl" -gt 1 ]; then
	MSG="More then one running AVD found. Please select one to install GP onto from following list:"
	if [ -n "$TUI" ]; then
		CMD="$TUI --radiolist \"$MSG\" 20 60 10 "
		for c in $(seq 0 $((cnt-1)))
		do
			[ $c -eq 0 ] && en=1 || en=0
			CMD="$CMD $((c+1)) \"${avds[$c]}\" $en "
		done
		CMD="$CMD 3>&1 1>&2 2>&3"
		echo "CMD : $CMD" # DEBUG
		choice=`eval $CMD`
		[ $? -ne 0 ] && at_exit -2
		AVD=${avds[$((choice-1))]}
	else
		echo $MSG
		for c in $(seq 0 $((cnt-1)))
		do
			echo " $((c+1))) ${avds[$c]} "
		done
		choice=""
		while [ -z "$choice" ]; do
			echo -n "Choose (1-${cnt},0=Cancel and exit): "
			read choice
			is_number $choice
			if [ $isnumber = NO ]; then
				echo "   INPUT ERR: $choice is not a number. Invalid entry, retry."
				choice=""
				continue
			else
				choice=$((choice+0))
			fi
			if [ $choice -lt 0 -o $choice -gt $cnt ]; then
				echo "Invalid entry. Must be between 1 e $cnt"'!'" (or 0 to exit)"
				choice=""
			fi

		done
		[ $choice -eq 0 ] && at_exit -2
		AVD=${avds[$((choice-1))]}
	fi
	SERIAL_OPTION="-s $AVD"
else
	AVD=${avds[0]}
fi

# ret=0
# echo "AVD: $AVD"
# exit $ret

TXT="Well. Now I will try to install Google Play on the following running AVD:
$AVD

You must be recalled that AVD has to be run with the '-writable-system' option
in order to write on its /system, otherwise the procedure will fail.
"

if [ -n "$TUI" ]; then
	TXT="$TXT Proceed? "
	$TUI --title "Proceed with install ..." --yesno "$TXT" 20 60
	[ $? -eq 0 ] || at_exit -2
else
	echo
	echo $TXT
	ans=""
	while [ -z "$ans" ]
	do
		echo -n "Proceed? (YySs/N/ ): "
		read ans
		ans=$(echo $ans | cut -c1 | tr [:lower:] [:upper:])
		if [ $ans != "Y" -a $ans != "S" -a $ans != "N" -a $ans != " " ]; then
			echo "INPUT ERR: Invalid answer."
			ans="" 
			continue
		fi
	done
	[ $ans = "S" -o $ans = "Y" ] || at_exit -2
fi


# echo "GO ON .."

### Enter to android's shell and get root:
###  ./adb shell
###  su
### 
### Check where system directory is mounted to:
###  cat /proc/mounts|grep system
### 
### And then remount it with 'rw' permissions:
###  mount -o rw,remount /dev/block/vda /system
### 
### Check if GoogleServicesFramework is present under /system/priv-app ....
### 
### 
### Restart adb as root and push Phonesky.apk:
###  ./adb root
###  ./adb push ~/Phonesky.apk /system/priv-app/
### 
### Restart avd:
###  ./adb shell stop
###  ./adb shell start
### 

# First, let's grant root access to device...
infobox "Asking root permission to device ... "
$ADB_PATH $SERIAL_OPTION root
sleep 1

# First of all, let's check to have a x86 AVD with Google Services ...
infobox "Checking if it's w/ Google API ... "
out=$($ADB_PATH $SERIAL_OPTION shell ls /system/priv-app/GoogleServicesFramework* 2>&1)
# Check No such file ..
if (echo $out | grep -q "No such file"); then 
	show_error "Seems that GoogleServicesFramework is not present
	AVD must be an Android VM with Google API to make it work."
	at_exit -3
fi
sleep 1

# remount /system RW
infobox "Remounting /system in rw"
outtmp=$($ADB_PATH $SERIAL_OPTION shell cat /proc/mounts|grep -w "\/system")
out=$(echo $outtmp | awk '{print $1}')
CMD="$ADB_PATH $SERIAL_OPTION shell mount -o rw,remount /system"
eval $CMD
sleep 1
# Recheck
outtmp=$($ADB_PATH $SERIAL_OPTION shell cat /proc/mounts|grep -w "\/system")
if !(echo $outtmp | grep -q "\/system"); then
	show_error "Something wrong in remounting /system. Please check before running this script again."
	at_exit -3
fi

# Check for x86 device ....
infobox "Checking for x86 virtual emulator .."
out=$($ADB_PATH $SERIAL_OPTION shell "cat /system/build.prop" | grep "^ro.product.device" | cut -f2 -d"=" | sed "s/\s//g")
if [ "$out" != "generic_x86" ]; then
	show_error "This scripts only works with x86 emulator. Please check before running this script again. ($out)"
	at_exit -3
fi
sleep 1

# Now checking version and distributing right Phonesky.apk
# /opt/Android/Sdk/platform-tools $ ./adb shell "cat /system/build.prop" | grep ro.build.version.release
# ro.build.version.release=7.1.1
# /opt/Android/Sdk/platform-tools $ ./adb shell "cat /system/build.prop" | grep ro.build.version.sdk
# ro.build.version.sdk=25
infobox "Checking android version ... "
out=$($ADB_PATH $SERIAL_OPTION shell "cat /system/build.prop" | grep "^ro.build.version.release" | cut -f2 -d"=")
case $out in
	4.4*) PHONESKY_SOURCE="repo/Phonesky.apk-x86-4.4"
		;;
	5.0*) PHONESKY_SOURCE="repo/Phonesky.apk-x86-5.0"
		;;
	5.1*) PHONESKY_SOURCE="repo/Phonesky.apk-x86-5.1"
		;;
	6.0*) PHONESKY_SOURCE="repo/Phonesky.apk-x86-6.0"
		;;
	7.0*) PHONESKY_SOURCE="repo/Phonesky.apk-x86-7.0"
		;;
	7.1*) PHONESKY_SOURCE="repo/Phonesky.apk-x86-7.1"
		;;
	*) PHONESKY_SOURCE="Err"
		;;
esac

if [ "$PHONESKY_SOURCE" = "Err" ]; then
	show_error "Can't recognize AVD android version, or it is not a supported ones.
	ro.build.version.release now is $out. Please check. Quitting."
	at_exit -4
fi

	
infobox "Pushing Phonesky.apk $out on device's /system/priv-app/ ... "
CMD="$ADB_PATH $SERIAL_OPTION push $PRGDIR/$PHONESKY_SOURCE /system/priv-app/Phonesky.apk"
eval $CMD
sleep 1


infobox " EVERYTHING DONE"'!'" Now I make restart the AVD. Please check if Google Play is correctly installed afterword "

$ADB_PATH $SERIAL_OPTION shell stop
$ADB_PATH $SERIAL_OPTION shell start

sleep 1

at_exit 0
