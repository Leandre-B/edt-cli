# If no flag -> timetable of this week
if [[ $# -eq 0 ]];then
    start=$(date -d "-$(( $(date +%u) - 1 )) days" +"%Y%m%d")
    end=$(date -d "$start + 4 days" +"%Y%m%d")
fi

# Check flag
while [[ $# -ne 0 ]];do
    case $1 in

        --help)

printf "edt.sh\n
\e[;;4mNAME\e[0m

edt.sh - affiche l'emploi du temps (UA)


\e[;;4mSYNOPSIS\e[0m

    ./edt.sh [OPTION]...


\e[;;4mDESCRIPTION\e[0m

    Affiche l'emploie du temps étudiant de l'Université d'Angers suivant l'id du groupe (--id).

    Par défault, le groupe est celui de la L2 I3 8-9-10.
    Pour savoir le quel correspont à votre groupe, regardez l'url de votre emploie du temps.
    La chaine à entrer est la concaténation de ce qui suit \"?type=\" et \"\$id=\".

    Ex : pour https://edt.univ-angers.fr/edt/ressource?type=G9FDC055BB1C34F92E0530100007F467B&id=EF2B4DCF5EF7B1FCE0532110A8C0FD79
        ./edt.sh --id G0B74A7B09B714798E0632110A8C09B7A


    --end YYYYMMDD
        Spécifie la fin de la plage à visuliser.
        Format : YYYYMMDD

    --id (id)
        Spécifie l'id du groupe (voir détail au dessus).

    --start YYYYMMDD
        Spécifie le début de la plage à visuliser.
        Format : YYYYMMDD

    --today [INTEGER]
        Affiche l'edt du jour +/-INTERGER (ou courant si non spécifié).

    --week
        Affiche l'edt de la semaine +/-INTERGER (ou courante si non spécifié).


\e[;;4mEXAMPLE\e[0m

    ./edt.sh --today +5
    ./edt.sh --week -2 --id G0B74A7B09B714798E0632110A8C09B7A


"


            exit

        ;;
        --start)
            shift
            start=$1
            ;;

        --end)
            shift
            end=$1
            ;;

        --week)
            shift

            # If $1 is a sign integer
            if [[ $1 =~ ^[+-]?[0-9]+$ ]];then

                # Start of the week (monday)
                # If current day is friday, do :
                #   date -d "-4 days"
                # where 4 is calculated with :
                #   index of current day -1
                # Can check week before (or after) by adding +-7

                start=$(date -d "-$(( $(date +%u) - 1 )) days + $(($1*7)) days" +"%Y%m%d")

            # If not, get current week
            else
                start=$(date -d "-$(( $(date +%u) - 1 )) days" +"%Y%m%d")
            fi

            # End is friday, so start + 4 days
            end=$(date -d "$start + 4 days" +"%Y%m%d")
            break;;

        --today)
            shift

            # If $1 is a sign integer
            if [[ $1 =~ ^[+-]?[0-9]+$ ]];then
                start=$(date -d "$1 days" +"%Y%m%d")

            #If not, get current day
            else
                start=$(date +"%Y%m%d")
            fi

            # We only want 1 day
            end=$start
            break
            ;;

        --id)
            shift
            id=$1
            ;;
    esac
    shift # Get next flag
done

# Exit if start or end are empty
if [[ -z $start ]] || [[ -z $end ]];then
    printf "ERROR : CHEK --help\n"
    exit 1
fi


# Id of group, replace by your own
id=G1D5BCAFF9A044378E0632110A8C0D50C

# Json response of the timetable
raw=$(curl -s https://edt.univ-angers.fr/edt/jsonSemaine --data 'id='$id'&dateDebut='$start'&dateFin='$end)


# Parse json
mapfile -t subject <<< "$(grep -Eo "\"titre\":([^-]*-){3}" <<< "$raw" | sed 's/"titre":"//')"

mapfile -t timetable_start <<<"$(grep -Eo "\"date_debut\":\".{16}" <<< "$raw"| sed 's/"date_debut":"//')"

mapfile -t timetable_end <<<"$(grep -Eo "\"date_fin\":\".{16}" <<< "$raw" | sed 's/"date_fin":"//')"


# Sort by time (sorted by subject in the json)
# Just a regular bubble sort
for (( i=0 ; i<(( ${#subject[@]} -1 )) ; i++ ));do
    for (( j=$i ; j<${#subject[@]} ; j++ ));do

        if [[  ${timetable_start[$i]} > ${timetable_start[$j]} ]];then

            aux=${subject[$i]}
            subject[$i]=${subject[$j]}
            subject[$j]=$aux

            aux=${timetable_start[$i]}
            timetable_start[$i]=${timetable_start[$j]}
            timetable_start[$j]=$aux

            aux=${timetable_end[$i]}
            timetable_end[$i]=${timetable_end[$j]}
            timetable_end[$j]=$aux

        fi

    done

done

# Get index of longest subject string (for better formating later)
longest=0
for (( i=1 ; i<${#subject[@]} ; i++ ));do
    if [[ ${#subject[$i]} -gt ${#subject[$longest]}  ]];then
        longest=$i
    fi
done

# If no subject (ie : longest==0)
if [[ ${#subject[$longest]} -eq 0 ]];then
    echo Nothing
    exit
fi

######## OUTPUT #########

# Print range of timetable
printf "\n$(date -d "$start" +"%A %d %B") - $(date -d "$end" +"%A %d %B")\n"


printf "\e[1;31m" #color

# Print "---.." delimiter according to the length of the longest string
for (( k=0 ; k<(( ${#subject[$longest]} + ${#timetable_start[$longest]} + ${#timetable_end[$longest]} + 13 )) ; ++k));do
    printf "-"
done
echo
# Loop trougth subject
for (( i=0 ; i<${#subject[@]} ; i++ ));do

    # Get infos
    day=$(cut -d '/' -f1 <<< "${timetable_start[$i]}")
    month=$(cut -d '/' -f2 <<< "${timetable_start[$i]}")
    year=$(grep -Eo "[0-9]{4}" <<< "${timetable_start[$i]}")
    start_time=$(cut -d ' ' -f2 <<< "${timetable_start[$i]}")
    end_time=$(cut -d ' ' -f2 <<< "${timetable_end[$i]}")

    if [[ $i -lt $(( ${#subject[@]} -1 ))  ]];then
        next_day=$(cut -d '/' -f1 <<< "${timetable_start[$(($i+1))]}")
    else
        next_day=$day
    fi

    # Newline with color
    printf "|\e[1;33m ${subject[$i]}"

    #fill with space for better formating
    for (( k=${#subject[$i]} ; k<${#subject[$longest]} ; ++k));do
        printf " "
    done

    #print time
    d=$(date -d "$month/$day/$year $start_time" +"%A %d %B %H:%M")
    printf "\e[1;31m | \e[1;34m $d ->\e[1;34m $end_time \e[1;31m\n"

    # Same as the other on above
    if [[ $day != $next_day ]];then
        for (( k=0 ; k<(( ${#subject[$longest]} + ${#timetable_start[$longest]} + ${#timetable_end[$longest]} + 13 )) ; ++k));do
            printf "-"
        done
        echo
    fi

done

for (( k=0 ; k<(( ${#subject[$longest]} + ${#timetable_start[$longest]} + ${#timetable_end[$longest]} + 13 )) ; ++k));do
    printf "-"
done

# Set colors to default
printf "\e[0m\n\n"
