#!/bin/bash


# /opt/Android/Sdk/platform-tools $ ./adb shell "cat /system/build.prop" | grep ro.build.version.release
# ro.build.version.release=7.1.1
# /opt/Android/Sdk/platform-tools $ ./adb shell "cat /system/build.prop" | grep ro.build.version.sdk
# ro.build.version.sdk=25

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


$ADB_PATH devices | grep -v -e "List of dev" -e "^$" | grep "^emulator-" > $TMP1
nl=`$CAT $TMP1 | $WC -l`


if [ "$nl" -eq 0 ]; then
	echo "No running AVD found. Please lunch at least one x86 AVD to install Google Play onto."
	at_exit -1
fi

# /opt/Android/Sdk/platform-tools/adb devices | grep -v -e "List of dev" -e "^$"


ret=$?
echo "Result: $ret"
exit $ret

at_exit 0
