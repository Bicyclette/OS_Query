#! /bin/sh

##### Variables

	##### Fichier temporaire pour la liste des 5 processus les plus gourmands en mémoire
	##### Et un autre fichier temporaire pour la liste des 5 plus gros fichiers réguliers, à partir du répertoire courant

	TMP_PROC="/tmp/proc.$$"
	TMP_DISK_USAGE="/tmp/disk_usage.$$"

	trap "rm -f $TMP_PROC $TMP_DISK_USAGE; exit 7" INT HUP QUIT ABRT SEGV TERM TSTP
	
	##### Nombre de ticks d'horloge par seconde

	TICKS_CLOCK_SEC=$( getconf CLK_TCK )
	
	##### Nombre de jours dans chaque mois

	JAN=31
	FEV_NBIS=28
	FEV_BIS=29
	MAR=31
	AVR=30
	MAI=31
	JUN=30
	JUL=31
	AOU=31
	SEP=30
	OCT=31
	NOV=30
	DEC=31

	##### Variable qui contiendra les éventuels processus non terminés par les signaux SIGHUP ou SIGTERM

	NOT_KILLED_PS=

	##### Variable indiquant si l'on doit effectuer l'envoi du signal SIGKILL à un processus ou non

	THIRD_TRY=0

##### Fonctions

	##### Affiche le nombre de jours contenu dans une année, selon si cette année est bissextile, ou non

	nb_days_year ()
	{
		if [ $(( $1 % 4 )) -eq 0 -a $(( $1 % 100 )) -ne 0 -o $(( $1 % 400 )) -eq 0 ]
		then
			echo 366
		else
			echo 365
		fi
	}

	##### Affiche le numéro du mois dans lequel on se trouve, pour une année donnée et sur quel jour de cette année on se trouve (ex: 285ème jour de l'année 1984)

	num_month ()
	{
		##### $1 le xème jour de l'année $2
		##### $2 l'année

		local DAYS=$(nb_days_year $2)

		if [ $DAYS -eq 365 ]
		then
			if [ $(( $1 - $JAN )) -le 0 ]
			then
				echo 1
			elif [ $(( $1 - ($JAN + $FEV_NBIS) )) -le 0 ]
			then
				echo 2
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR) )) -le 0 ]
			then
				echo 3
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR) )) -le 0 ]
			then
				echo 4
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI) )) -le 0 ]
			then
				echo 5
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN) )) -le 0 ]
			then
				echo 6
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL) )) -le 0 ]
			then
				echo 7
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU) )) -le 0 ]
			then
				echo 8
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP) )) -le 0 ]
			then
				echo 9
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT) )) -le 0 ]
			then
				echo 10
			elif [ $(( $1 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT + $NOV) )) -le 0 ]
			then
				echo 11
			else
				echo 12
			fi
		else
			if [ $(( $1 - $JAN )) -le 0 ]
			then
				echo 1
			elif [ $(( $1 - ($JAN + $FEV_BIS) )) -le 0 ]
			then
				echo 2
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR) )) -le 0 ]
			then
				echo 3
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR) )) -le 0 ]
			then
				echo 4
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI) )) -le 0 ]
			then
				echo 5
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN) )) -le 0 ]
			then
				echo 6
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL) )) -le 0 ]
			then
				echo 7
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU) )) -le 0 ]
			then
				echo 8
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP) )) -le 0 ]
			then
				echo 9
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT) )) -le 0 ]
			then
				echo 10
			elif [ $(( $1 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT + $NOV) )) -le 0 ]
			then
				echo 11
			else
				echo 12
			fi
		fi
	}

	##### Affiche sur quel jour on se positionne pour un mois donné

	num_day ()
	{
		##### $1 le numéro du mois
		##### $2 le xème jour de l'année y
		##### $3 le nombre de jours dans l'année (365 si non bissextile, 366 sinon)

		if [ $3 -eq 365 ]
		then
			case $1 in
				1) echo $2;;
				2) echo $(( $2 - $JAN ));;
				3) echo $(( $2 - ($JAN + $FEV_NBIS)  ));;
				4) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR) ));;
				5) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR) ));;
				6) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI) ));;
				7) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN) ));;
				8) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL) ));;
				9) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU) ));;
				10) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP) ));;
				11) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT) ));;
				12) echo $(( $2 - ($JAN + $FEV_NBIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT + $NOV) ));;
			esac
		else
			case $1 in
				1) echo $2;;
				2) echo $(( $2 - $JAN ));;
				3) echo $(( $2 - ($JAN + $FEV_BIS)  ));;
				4) echo $(( $2 - ($JAN + $FEV_BIS + $MAR) ));;
				5) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR) ));;
				6) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI) ));;
				7) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN) ));;
				8) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL) ));;
				9) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU) ));;
				10) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP) ));;
				11) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT) ));;
				12) echo $(( $2 - ($JAN + $FEV_BIS + $MAR + $AVR + $MAI + $JUN + $JUL + $AOU + $SEP + $OCT + $NOV) ));;
			esac
		fi
	}

	##### Affiche les n plus gros fichiers à partir d'un certain répertoire passé en paramètre

	n_most_heavy_files ()
	{
		local CUR_DIR=$1
		NB=$2

		for FILE in $(ls $1)
		do
			CUR_FILE=${CUR_DIR}/${FILE}

			if [ -f "$CUR_FILE" ]
			then
				du -b "$CUR_FILE" >> $TMP_DISK_USAGE
			elif [ -d "$CUR_FILE" ]
			then
				CUR_FILE="${CUR_FILE}"
				n_most_heavy_files $CUR_FILE $2
			fi
		done
	}

	##### Affiche la date du dernier boot système

	dernier_boot ()
	{
	
		##### Uptime en secondes

		UPTIME=$( cat /proc/uptime | cut -d " " -f 1 | cut -d "." -f 1 )

		##### Jours, heures, minutes et secondes passées depuis le dernier boot

		DAY=$(( $UPTIME / 86400  ))
		HOUR=$(( ( $UPTIME / 3600 ) - ( $DAY * 24 ) ))
		MIN=$(( ( $UPTIME / 60 ) - (( $DAY * 1440 ) + ( $HOUR * 60 )) ))
		SEC=$(( $UPTIME - (( $DAY * 86400 ) + ( $HOUR * 3600 ) + ( $MIN * 60 )) ))

		##### Date actuelle

		DATE_DAY_YEAR=$( date +%j )
		DATE_DAY=$( date +%d )
		DATE_MONTH=$( date +%m )
		DATE_YEAR=$( date +%Y )

		DATE_H=$( date +%H )
		DATE_H=$( echo "obase=10;$DATE_H" | bc )
		DATE_M=$( date +%M )
		DATE_M=$( echo "obase=10;$DATE_M" | bc )
		DATE_S=$( date +%S )
		DATE_S=$( echo "obase=10;$DATE_S" | bc )

		##### Pour la suite de cette section, le but est de réaliser cette opération : date actuelle - temps écoulé depuis le boot = date du boot

		BOOT_D=$(( $DATE_DAY_YEAR - $DAY ))
		BOOT_Y=$DATE_YEAR

		##### DECREMENT = nombre d'années en arrière (si BOOT_D < 0)
		##### BOOT_D final après le(s) tour(s) de boucle = nombre de jours après le début de l'année (en arrière)

		DECREMENT=0

		if [ $BOOT_D -lt 0 ]
		then
			while [ $BOOT_D -lt 0 ]
			do
				DECREMENT=$(( $DECREMENT + 1 ))
				NEW_YEAR=$(( $DATE_YEAR - $DECREMENT ))
				BOOT_D=$(( $(nb_days_year $NEW_YEAR) + $BOOT_D ))
			done
		else
			BOOT_M=$(num_month $BOOT_D $BOOT_Y)
			TMP_DAYS=$(nb_days_year $BOOT_Y)
			BOOT_D=$(num_day $BOOT_M $BOOT_D $TMP_DAYS)
		fi

		if [ $DECREMENT -ne 0 ]
		then
			BOOT_Y=$(( $BOOT_Y - $DECREMENT ))
		fi

		BOOT_HOUR=$(( $DATE_H - $HOUR ))
		BOOT_MIN=$(( $DATE_M - $MIN ))
		BOOT_SEC=$(( $DATE_S - $SEC ))

		if [ $BOOT_HOUR -lt 0 ]
		then
			BOOT_D=$(( $BOOT_D - 1 ))
			BOOT_HOUR=$(( $BOOT_HOUR + 24 ))
		fi

		if [ $BOOT_MIN -lt 0 ]
		then
			BOOT_HOUR=$(( $BOOT_HOUR - 1 ))
			BOOT_MIN=$(( $BOOT_MIN + 60 ))
			BOOT_SEC=$(( $BOOT_SEC + 60 ))
			if [ $BOOT_SEC -lt 0 ]
			then
				BOOT_MIN=$(( $BOOT_MIN - 1 ))
				BOOT_SEC=$(( $BOOT_SEC + 60 ))
			fi
		fi

		if [ $BOOT_SEC -lt 0 ]
		then
			BOOT_MIN=$(( $BOOT_MIN - 1 ))
			BOOT_SEC=$(( $BOOT_SEC + 60 ))
		fi

		echo "	Dernier boot : ${BOOT_D}/${BOOT_M}/${BOOT_Y} ${BOOT_HOUR}h:${BOOT_MIN}min:${BOOT_SEC}sec (UTC$(date +%z))"
	}

	##### Charge dans un fichier temporaire des informations (pid, nom, mémoire reservée, temps processeur, date de lancement, priorité) pour chaque processus executé par le système

	infos_proc ()
	{
		for ELEM in $(ls /proc)
		do
			DIR="/proc/$ELEM"
			if [ -d $DIR ]
			then
				if [ $( echo $ELEM | grep -E "^[[:digit:]]+$") ]
				then
					if [ $ELEM -ne 1 ]
					then
						##### PID du programme

						PID=$( cat $DIR/stat | cut -d " " -f 1 )

						##### Nom du programme

						PROG=$( cat $DIR/stat | cut -d " " -f 2 )
				
						##### Conso en kB
				
						CONSO=$( cat $DIR/statm | cut -d " " -f 1 )

						##### Temps écoulé depuis le lancement

						CPU=$( cat $DIR/stat | cut -d " " -f 14)
						CPU=$(( $CPU / $TICKS_CLOCK_SEC ))
						CPU="${CPU}s"

						##### Date de lancement

						STARTTIME=$( cat $DIR/stat | cut -d " " -f 22 )
						STARTTIME=$(( $STARTTIME / $TICKS_CLOCK_SEC ))
						STARTTIME="${STARTTIME}s"

						##### Priorité

						PRIO=$( cat $DIR/stat | cut -d " " -f 19 )

						##### Total des infos (concaténation) pour un programme

						if [ "$1" = "mem" ]
						then
							LINE="$CONSO $PROG $PID $CPU $PRIO $STARTTIME"
						elif [ "$1" = "cpu" ]
						then
							LINE="$CPU $PROG $PID $CONSO $PRIO $STARTTIME"
						elif [ "$1" = "prio" ]
						then
							LINE="$PRIO $PROG $PID $CPU $CONSO $STARTTIME"
						else
							LINE="$STARTTIME $PROG $PID $CPU $PRIO $CONSO"
						fi
						echo $LINE >> $TMP_PROC
					fi
				fi
			fi
		done
	}

	##### Affiche les n processus et n fichiers réguliers selon un certain critère de tri et à partir d'un certain répertoire

	code_generique_mode_interactif ()
	{
		##### Affichage des n processus
		
		if [ -z $1 ]
		then
			AFF_NB=5
		else
			AFF_NB=$1
		fi

		if [ -z $2 ]
		then
			SORT_METHOD="mem"
			infos_proc $SORT_METHOD
			echo "Processus : $AFF_NB processus triés par quantité de mémoire"
			echo ""
		else
			SORT_METHOD=$2
			infos_proc $SORT_METHOD
			if [ "$SORT_METHOD" = "mem" ]
			then
				echo "Processus : $AFF_NB processus triés par quantité de mémoire"
				echo ""
			elif [ "$SORT_METHOD" = "cpu" ]
			then
				echo "Processus : $AFF_NB processus triés par temps écoulé depuis le lancement"
				echo ""
			elif [ "$SORT_METHOD" = "prio" ]
			then
				echo "Processus : $AFF_NB processus triés par priorité"
				echo ""
			else
				echo "Processus : $AFF_NB processus triés par date de lancement"
				echo ""
			fi
		fi

		if [ -z $3 ]
		then
			CURRENT_DIR=$PWD
		else
			CURRENT_DIR=$3
		fi

		echo "	-------------------------------------------------------------------------------------------------"
		echo "	|            PID|             PROGRAM NAME|      VSIZE(kB)|       CPU|      PRIO|      STARTTIME|"
		echo "	-------------------------------------------------------------------------------------------------"

		if [ "$SORT_METHOD" = "mem" ]
		then
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $1, $4, $5, $6)}'
		elif [ "$SORT_METHOD" = "cpu" ]
		then
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $4, $1, $5, $6)}'
		elif [ "$SORT_METHOD" = "prio" ]
		then
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $5, $4, $1, $6)}'
		else
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $6, $4, $5, $1)}'
		fi

		echo "" > $TMP_PROC

		##### Affichage des n fichiers réguliers occupant le plus d'espace disque à partir d'un certain répertoire

		echo ""
		echo "Fichiers"
		echo ""

		echo "	-----------------------------------------------------------------------------------------------------------------------------------"
		echo "	|  SIZE(Bytes)|                                                                                                               FILE|"
		
		n_most_heavy_files $CURRENT_DIR $AFF_NB
		
		##### Puis on tri le fichier par ordre décroissant et on affiche les $2 premières lignes

		echo "	-----------------------------------------------------------------------------------------------------------------------------------"
		cat $TMP_DISK_USAGE | sort -nr | head -$NB | awk -F'	' '{printf("	|%13s|%115s|\n	-----------------------------------------------------------------------------------------------------------------------------------\n", $1,$2)}'
	}

	code_generique_mode_interactif_sort ()
	{
		##### Affichage des n processus
	
		if [ -z $1 ]
		then
			AFF_NB=5
		fi

		if [ -z $2 ]
		then
			infos_proc "mem"
			echo "Processus : $AFF_NB processus triés par quantité de mémoire"
			echo ""
		else
			infos_proc $2
			if [ "$2" = "mem" ]
			then
				echo "Processus : $AFF_NB processus triés par quantité de mémoire"
				echo ""
			elif [ "$2" = "cpu" ]
			then
				echo "Processus : $AFF_NB processus triés par temps écoulé depuis le lancement"
				echo ""
			elif [ "$2" = "prio" ]
			then
				echo "Processus : $AFF_NB processus triés par priorité"
				echo ""
			else
				echo "Processus : $AFF_NB processus triés par date de lancement"
				echo ""
			fi
		fi

		echo "	-------------------------------------------------------------------------------------------------"
		echo "	|            PID|             PROGRAM NAME|      VSIZE(kB)|       CPU|      PRIO|      STARTTIME|"
		echo "	-------------------------------------------------------------------------------------------------"

		if [ "$2" = "mem" ]
		then
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $1, $4, $5, $6)}'
		elif [ "$2" = "cpu" ]
		then
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $4, $1, $5, $6)}'
		elif [ "$2" = "prio" ]
		then
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $5, $4, $1, $6)}'
		else
			cat $TMP_PROC | sort -nr | head -$AFF_NB | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $6, $4, $5, $1)}'
		fi
	}

	code_generique_mode_interactif_cd ()
	{
		##### Affichage des n fichiers réguliers occupant le plus d'espace disque à partir d'un certain répertoire

		if [ -z $2 ]
		then
			CURRENT_DIR=$PWD
		else
			CURRENT_DIR=$2
		fi

		echo ""
		echo "Fichiers"
		echo ""

		echo "	-----------------------------------------------------------------------------------------------------------------------------------"
		echo "	|  SIZE(Bytes)|                                                                                                               FILE|"
		
		n_most_heavy_files $CURRENT_DIR $1

		##### Puis on tri le fichier par ordre décroissant et on affiche les $2 premières lignes

		echo "	-----------------------------------------------------------------------------------------------------------------------------------"
		cat $TMP_DISK_USAGE | sort -nr | head -$NB | awk -F'	' '{printf("	|%13s|%115s|\n	-----------------------------------------------------------------------------------------------------------------------------------\n", $1,$2)}'
	}

	##### Vérifie si une chaîne de caractère est contenue dans une autre chaîne de caractère avec séparateur

	sous_chaine ()
	{
		GRANDE_CHAINE=$1
		PETITE_CHAINE=$2
		NF=$( echo $GRANDE_CHAINE | tr , " " | wc -w )
		POS=1
		FOUND=0

		while [ $POS != $NF -a $FOUND = 0 ]
		do
			CURRENT_VALUE=$( echo $GRANDE_CHAINE | cut -d "," -f $POS )
			if [ $CURRENT_VALUE = $PETITE_CHAINE ]
			then
				FOUND=1
			fi
			POS=$(( $POS + 1 ))
		done
		
		echo $FOUND
	}

	##### Retire d'une chaîne de caractère, une portion de caractères qui est une sous chaîne de cette chaîne de caractère

	remove_pid_from_string ()
	{
		STRING=$1
		PID=$2

		STRING=$( echo $STRING | sed "s/$PID//" )
		echo $STRING
	}

####################################################################################################
############################################DEBUT SCRIPT############################################
####################################################################################################

I_FLAG=0
D_FLAG=0
S_FLAG=0
N_FLAG=0

AFF_NB=5
CURRENT_DIR=$PWD
SORT_METHOD="mem"

while getopts :id:s:n: NAME
do
	case $NAME in
		i) 
		I_FLAG=1;
		;;
	
		d) 
		D_FLAG=1;
		if [ -d "$OPTARG" ]
		then
			CURRENT_DIR=$OPTARG;
		else
			echo "Erreur : le répertoire renseigné est invalide !" >&2;
			echo "Usage  : ./projet [-i] [-d répertoire] [-s critère] [-n nblignes]" >&2;
			echo "         critère = {mem | cpu | prio | start}" >&2;
			exit 1;
		fi
		;;

		s) 
		S_FLAG=1;
		SORT_METHOD=$OPTARG;

		if ! [ $SORT_METHOD = "cpu" -o $SORT_METHOD = "mem" -o $SORT_METHOD = "prio" -o $SORT_METHOD = "start" ]
		then
			echo "Erreur : la méthode de tri des processus est incorrecte !" >&2;
			echo "Usage  : ./projet [-i] [-d répertoire] [-s critère] [-n nblignes]" >&2;
			echo "         critère = {mem | cpu | prio | start}" >&2;
			exit 2;
		fi
		;;
		
		n)
		N_FLAG=1;
		AFF_NB=$OPTARG;

		if ! [ $( echo $AFF_NB | grep -E "^[[:digit:]]+$" ) ]
		then
			echo "Erreur : vous devez renseigner un nombre entier valide pour l\'option -n !" >&2;
			echo "Usage  : ./projet [-i] [-d répertoire] [-s critère] [-n nblignes]" >&2;
			echo "         critère = {mem | cpu | prio | start}" >&2;
			exit 3;
		fi
		;;

		:) 
		echo "Erreur : -$OPTARG requiert un argument !" >&2; 
		echo "Usage  : ./projet [-i] [-d répertoire] [-s critère] [-n nblignes]" >&2;
		echo "         critère = {mem | cpu | prio | start}" >&2;
		exit 4;
		;;
		
		?)
		if [ $OPTARG == "--" ]
		then
			echo "Fin des options !" >&2;
			exit 5;
		else
			echo "Erreur : -$OPTARG n'est pas une option valide !" >&2;
			echo "Usage  : ./projet [-i] [-d répertoire] [-s critère] [-n nblignes]" >&2;
			echo "         critère = {mem | cpu | prio | start}" >&2;
			exit 6;
		fi
		;;
	esac
done

if [ $I_FLAG -eq 0 ]
then
	DEFAULT_DIR=$PWD
	DEFAULT_NB=5

	##### Affichage des informations systèmes classiques

	echo "Système"

	echo "	$(cat /proc/sys/kernel/ostype) $(cat /proc/sys/kernel/osrelease)"

	dernier_boot

	echo "	Nombre d'utilisateurs connectés : $(who -u | wc -l)"

	echo ""

	##### Affichage par défaut des 5 processus occupant le plus de mémoire

	infos_proc "mem"

	echo "Processus : 5 processus triés par quantité de mémoire"
	echo ""

	echo "	-------------------------------------------------------------------------------------------------"
	echo "	|            PID|             PROGRAM NAME|      VSIZE(kB)|       CPU|      PRIO|      STARTTIME|"
	echo "	-------------------------------------------------------------------------------------------------"
	cat $TMP_PROC | sort -nr | sed -n '1,5 p' | awk -F' ' '{printf ("	|%15s|%25s|%15s|%10s|%10s|%15s|\n	-------------------------------------------------------------------------------------------------\n", $3, $2, $1, $4, $5, $6)}'

	##### Affichage par défaut des 5 fichiers réguliers occupant le plus d'espace disque à partir du répertoire courant

	echo ""
	echo "Fichiers"
	echo ""

	echo "	-----------------------------------------------------------------------------------------------------------------------------------"
	echo "	|  SIZE(Bytes)|                                                                                                               FILE|"
	
	n_most_heavy_files $DEFAULT_DIR $DEFAULT_NB

	##### Puis on tri le fichier par ordre décroissant et on affiche les $DEFAULT_NB premières lignes

	echo "	-----------------------------------------------------------------------------------------------------------------------------------"
	cat $TMP_DISK_USAGE | sort -nr | head -$DEFAULT_NB | awk -F'	' '{printf("	|%13s|%115s|\n	-----------------------------------------------------------------------------------------------------------------------------------\n", $1,$2)}'

else
	##### Affichage des informations systèmes classiques

	echo "Système"

	echo "	$(cat /proc/sys/kernel/ostype) $(cat /proc/sys/kernel/osrelease)"

	dernier_boot

	echo "	Nombre d'utilisateurs connectés : $(who -u | wc -l)"

	echo ""

	code_generique_mode_interactif $AFF_NB $SORT_METHOD $CURRENT_DIR
	
	LINE="start"

	while [ "$LINE" != "quit" ]
	do
		if [ "$LINE" = "quit" ]
		then
			exit 0
		else
			echo -n "> "
			read LINE

			if [ "$LINE" = "quit" ]
			then
				exit 0
			fi

			if [ "$( echo $LINE | tr -s [:blank:] | cut -d " " -f 1 )" = "top" ]
			then
				NF=$( echo $LINE | tr -s [[:blank:]] | wc -w )
				if [ $NF -eq 2 ]
				then
					CHAMPS_2=$( echo $LINE | tr -s [[:blank:]] | cut -d " " -f 2 )
					if [ $( echo $CHAMPS_2 | grep -E "^[[:digit:]]+$" ) ]
					then
						AFF_NB=$CHAMPS_2
						code_generique_mode_interactif $AFF_NB $SORT_METHOD $CURRENT_DIR
						echo "" > $TMP_DISK_USAGE
					else
						echo "	Erreur : vous devez transmettre un nombre entier naturel à top !" >&2
					fi
				elif [ $NF -gt 2 ]
				then
					echo "	Erreur : trop d'arguments renseignés, top ne prends qu'un argument !" >&2
				else
					echo "	Erreur : nombre insuffisant d'argument, top prends un et un seul argument !" >&2
					echo "	Usage  : top <nombre entier>" >&2
				fi
			elif [ "$( echo $LINE | tr -s [:blank:] | cut -d " " -f 1 )" = "sort" ]
			then
				NF=$( echo $LINE | tr -s [[:blank:]] | wc -w )
				if [ $NF -eq 2 ]
				then
					CHAMPS_2=$( echo $LINE | tr -s [[:blank:]] | cut -d " " -f 2 )
					if [ "$CHAMPS_2" = "mem" -o "$CHAMPS_2" = "cpu" -o "$CHAMPS_2" = "prio" -o "$CHAMPS_2" = "start" ]
					then
						SORT_METHOD=$CHAMPS_2
						code_generique_mode_interactif_sort $AFF_NB $SORT_METHOD
						echo "" > $TMP_PROC
					else
						echo "	Erreur : vous devez transmettre à sort une des valeurs suivantes => (mem|cpu|prio|start) !" >&2
					fi
				elif [ $NF -gt 2 ]
				then
					echo "	Erreur : trop d'arguments renseignés, sort ne prends qu'un argument !" >&2
				else
					echo "	Erreur : nombre insuffisant d'argument, sort prends un et un seul argument !" >&2
					echo "	Usage  : sort <mem | cpu | prio | start>" >&2
				fi
			elif [ "$( echo $LINE | tr -s [:blank:] | cut -d " " -f 1 )" = "cd" ]
			then
				NF=$( echo $LINE | tr -s [[:blank:]] | wc -w )
				if [ $NF -eq 2 ]
				then
					CHAMPS_2=$( echo $LINE | tr -s [[:blank:]] | cut -d " " -f 2 )
					if [ -d "$CHAMPS_2" ]
					then
						CURRENT_DIR=$CHAMPS_2
						code_generique_mode_interactif_cd $AFF_NB $CURRENT_DIR
						echo "" > $TMP_DISK_USAGE
					else
						echo "	Erreur : vous devez transmettre à cd un chemin valide vers un repertoire existant !" >&2
					fi
				elif [ $NF -gt 2 ]
				then
					echo "	Erreur : trop d'arguments renseignés, cd ne prends qu'un argument !" >&2
				else
					echo "	Erreur : nombre insuffisant d'argument, cd prends un et un seul argument !" >&2
					echo "	Usage  : cd <chemin>" >&2
				fi
			elif [ "$( echo $LINE | tr -s [:blank:] | cut -d " " -f 1 )" = "renice" ]
			then
				NF=$( echo $LINE | tr -s [[:blank:]] | wc -w )
				if [ $NF -eq 3 ]
				then
					CHAMPS_2=$( echo $LINE | tr -s [[:blank:]] | cut -d " " -f 2 )
					CHAMPS_3=$( echo $LINE | tr -s [[:blank:]] | cut -d " " -f 3 )
					if [ $( echo $CHAMPS_2 | grep -E "^[[:digit:]]+$" ) -a $( echo $CHAMPS_3 | grep -E "^-?[[:digit:]]+$" ) ]
					then
						if [ -d "/proc/$CHAMPS_2" ]
						then
							renice $CHAMPS_3 -p $CHAMPS_2
						else
							echo "Erreur : le nombre renseigné n'est pas un PID valide (n'est donc attaché à aucun processus existant) !" >&2
						fi
					else
						echo "	Erreur : vous devez transmettre à renice un PID suivit d'une valeur numérique pour définir la nouvelle priorité à appliquer !" >&2
					fi
				elif [ $NF -gt 2 ]
				then
					echo "	Erreur : trop d'arguments renseignés, renice ne prends que deux arguments !" >&2
				else
					echo "	Erreur : nombre insuffisant d'argument, renice prends deux arguments !" >&2
					echo "	Usage  : renice <pid> <priorité>" >&2
					echo "		 priorité prends des valeurs entre 19 (basse priorité) et -20 (haute priorité)" >&2
				fi
			elif [ "$( echo $LINE | tr -s [:blank:] | cut -d " " -f 1 )" = "kill" ]
			then
				NF=$( echo $LINE | tr -s [[:blank:]] | wc -w )
				if [ $NF -eq 2 ]
				then
					CHAMPS_2=$( echo $LINE | tr -s [[:blank:]] | cut -d " " -f 2 )
					if [ $( echo $CHAMPS_2 | grep -E "^[[:digit:]]+$" ) ]
					then
						if [ -d "/proc/$CHAMPS_2" ]
						then
							kill -HUP $CHAMPS_2

							if [ $(sous_chaine $NOT_KILLED_PS $CHAMPS_2) = 1 ]
							then
								kill -TERM $CHAMPS_2
								if [ -d "/proc/$CHAMPS_2" ]
								then
									if [ $THIRD_TRY = 0 ]
									then
										echo "	Le processus attaché au PID $CHAMPS_2 n'a pas pu être terminé ! (deuxième tentative SIGTERM)"
										THIRD_TRY=1
									else
										kill -KILL $CHAMPS_2
										if [ -d "/proc/$CHAMPS_2" ]
										then
											echo "	Le processus attaché au PID $CHAMPS_2 a été terminé correctement !"
											remove_pid_from_string $NOT_KILLED_PS $CHAMPS_2
											THIRD_TRY=0
										else
											echo "	Le processus attaché au PID $CHAMPS_2 n'a pas pu être terminé ! (troisième tentative SIGKILL)"
										fi
									fi
								else
									echo "	Le processus attaché au PID $CHAMPS_2 a été terminé correctement !"
									remove_pid_from_string $NOT_KILLED_PS $CHAMPS_2
								fi
							fi

							if [ -d "/proc/$CHAMPS_2" -a $(sous_chaine $NOT_KILLED_PS $CHAMPS_2) = 0 ]
							then
								NOT_KILLED_PS="$CHAMPS_2,$NOT_KILLED_PS"
								echo "	Le processus attaché au PID $CHAMPS_2 n'a pas pu être terminé ! (première tentative SIGHUP)"
							fi
						else
							echo "Erreur : le nombre renseigné n'est pas un PID valide (n'est donc attaché à aucun processus existant) !" >&2
						fi
					else
						echo "	Erreur : vous devez transmettre à kill un PID !" >&2
					fi
				elif [ $NF -gt 2 ]
				then
					echo "	Erreur : trop d'arguments renseignés, kill ne prends qu'un argument !" >&2
				else
					echo "	Erreur : nombre insuffisant d'argument, kill prends un et un seul argument !" >&2
					echo "	Usage  : kill <pid>" >&2
				fi
			else
				echo "Erreur : la commande saisie est incorrecte !" >&2
				echo "         Voici la liste des commandes acceptées et entre parenthèses le/les argument(s) qu'elles prennent et leurs types : " >&2
				echo "         top (nombre : entier)" >&2
				echo "         sort (critère : chaîne de caractères)" >&2
				echo "         cd (chemin : chaîne de caractères)" >&2
				echo "	       kill (pid : entier)" >&2
				echo "	       renice (pid, prio : nombre, nombre)" >&2
			fi
		fi
	done
fi
exit 0
