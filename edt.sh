# Si pas d'option -> comportement par défaut
# affiche l'edt de la semaine courante
if [[ $# -eq 0 ]];then
    start=$(date -d "-$(( $(date +%u) - 1 )) days" +"%Y%m%d")
    end=$(date -d "$start + 4 days" +"%Y%m%d")
fi

# ==== Traitement des options ====
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


    --date YYYYMMDD YYYYMMDD
        Spécifie la plage à visualiser (debut fin).

    --id (id)
        Spécifie l'id du groupe (voir détail au dessus).

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
        --date)
            shift
            start=$1
            
            shift
            end=$1
            ;;

        --week)
            shift

            # Si $1 est un entier signé (commande du type --week +2 où $1 = +2)
            if [[ $1 =~ ^[+-]?[0-9]+$ ]];then

                # Determine la date du 1er jour de la semaine (lundi)
                # en fonction de la date courante

                # ex : nous sommes vendredi (jour 5) et je veux l'edt dans 2 semaines : 
                # start = date - (5-1)_jours + 7_jours * 2  

                start=$(date -d "-$(( $(date +%u) - 1 )) days + $(($1*7)) days" +"%Y%m%d")

            # Sinon, semaine courante
            else
                start=$(date -d "-$(( $(date +%u) - 1 )) days" +"%Y%m%d")
            fi

            # start + 4_jours
            end=$(date -d "$start + 4 days" +"%Y%m%d")
            break;;

        --today)
            shift

            # Si $1 est un entier signé (commande du type --today +2 où $1 = +2)
            if [[ $1 =~ ^[+-]?[0-9]+$ ]];then
                start=$(date -d "$1 days" +"%Y%m%d")

            # Sinon, jour courant
            else
                start=$(date +"%Y%m%d")
            fi

            # On ne veut seulement qu'un jour
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
# ==== Fin du traitement des options ====

# Exit si start ou end sont vides
if [[ -z $start ]] || [[ -z $end ]];then
    printf "ERROR : CHEK --help\n"
    exit 1
fi


# L'id du group par défault - peut être remplacer par le votre
id=G1D5BCAFF9A044378E0632110A8C0D50C

# JSON de l'EDT
# requete POST
# dates de la forme 'YYYYMMDD' 
raw=$(curl -s https://edt.univ-angers.fr/edt/jsonSemaine --data 'id='$id'&dateDebut='$start'&dateFin='$end)

# Si y'a aucun cours raw='[]'
if [[ ${#raw} -eq 2 ]];then
    echo Nothing
    exit
fi


# Parse json
# Construction de 3 tableaux

# Intitulés des cours
mapfile -t titres_cours <<< "$(grep -Eo "\"titre\":([^-]*-){3}" <<< "$raw" | sed 's/"titre":"//')"

# Intitulé du cours
mapfile -t dates_debut_cours <<<"$(grep -Eo "\"date_debut\":\".{16}" <<< "$raw"| sed 's/"date_debut":"//')"

# Intitulé du cours
mapfile -t dates_fin_cours <<<"$(grep -Eo "\"date_fin\":\".{16}" <<< "$raw" | sed 's/"date_fin":"//')"

# On trie les tableaux ordre chronologique
# Classique bubble sort
for (( i=0 ; i<(( ${#titres_cours[@]} -1 )) ; i++ ));do
    for (( j=$i ; j<${#titres_cours[@]} ; j++ ));do

        if [[  ${dates_debut_cours[$i]} > ${dates_debut_cours[$j]} ]];then

            aux=${titres_cours[$i]}
            titres_cours[$i]=${titres_cours[$j]}
            titres_cours[$j]=$aux

            aux=${dates_debut_cours[$i]}
            dates_debut_cours[$i]=${dates_debut_cours[$j]}
            dates_debut_cours[$j]=$aux

            aux=${dates_fin_cours[$i]}
            dates_fin_cours[$i]=${dates_fin_cours[$j]}
            dates_fin_cours[$j]=$aux

        fi

    done

done

# ===== Affichage console ======

# Période de l'EDT choisie (start et end)
printf "\n$(date -d "$start" +"%A %d %B") - $(date -d "$end" +"%A %d %B")\n"


printf "\e[1;31m"

# Récupére l'index du plus long cours (taille de la string)
longest=0
for (( i=1 ; i<${#titres_cours[@]} ; i++ ));do
    if [[ ${#titres_cours[$i]} -gt ${#titres_cours[$longest]}  ]];then
        longest=$i
    fi
done

# Print "---.." delimiteur de la taille du cours le plus long
for (( k=0 ; k<(( ${#titres_cours[$longest]} + ${#dates_debut_cours[$longest]} + ${#dates_fin_cours[$longest]} + 13 )) ; ++k));do
    printf "-"
done

echo
# pour tout les cours
for (( i=0 ; i<${#titres_cours[@]} ; i++ ));do

    # Récuperer les infos
    day=$(cut -d '/' -f1 <<< "${dates_debut_cours[$i]}")
    month=$(cut -d '/' -f2 <<< "${dates_debut_cours[$i]}")
    year=$(grep -Eo "[0-9]{4}" <<< "${dates_debut_cours[$i]}")
    start_time=$(cut -d ' ' -f2 <<< "${dates_debut_cours[$i]}")
    end_time=$(cut -d ' ' -f2 <<< "${dates_fin_cours[$i]}")

    # Cours
    printf "|\e[1;33m ${titres_cours[$i]}"

    # Ajout d'espace pour aligner avec la taille du plus long cours
    for (( k=${#titres_cours[$i]} ; k<${#titres_cours[$longest]} ; ++k));do
        printf " "
    done

    # Date
    d=$(date -d "$month/$day/$year $start_time" +"%A %d %B %H:%M")
    printf "\e[1;31m | \e[1;34m $d ->\e[1;34m $end_time \e[1;31m\n"

    # Récupère le jour du prochaine cours
    next_day=$(cut -d '/' -f1 <<< "${dates_debut_cours[$(($i+1))]}")

    # Si le cours suivant n'est pas le même jour
    # Print "---.." delimiteur de la taille du cours le plus long
    if [[ $day != $next_day ]];then
        for (( k=0 ; k<(( ${#titres_cours[$longest]} + ${#dates_debut_cours[$longest]} + ${#dates_fin_cours[$longest]} + 13 )) ; ++k));do
            printf "-"
        done
        echo
    fi

done


# Remet les courleurs par défaut
printf "\e[0m\n\n"
