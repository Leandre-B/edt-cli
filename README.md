
# edt-cli
L'emploi du temps universitaire d'Angers en ligne de commande


## Fonctionnement
(--help)  
Une requête POST est fait à https://edt.univ-angers.fr/edt/jsonSemaine avec un payload de la forme :  

```
id	"G1D5BCAFF9A044378E0632110A8C0D50C"
dateDebut	"20261026"
dateFin	"20261101"
```
(l'id correspond à celui se trouvant dans l'url de l'EDT préfixé de la lettre 'G')  
La réponse est un fichier JSON de la forme  
```
[
    {"id":"123",  
    "titre":"TP/CM/TD/Conférence - Salle - Description - Groupe1, Groupe2",
    "titre_long":"NomCours - Salle - Description - Groupe1, Groupe2 - Enseignant",
    "description":"string_de_tritre_longs_abbrégeé",
    "date_debut":"25/11/2026 17:00:00",
    "date_fin":"25/11/2026 18:00:00",
    "categorie":"Conférence",
    "couleur":"#0000FF",
    "enseignant":["Ensg1", "Ensg2"],
    ... et autres infos
},

],
[...]
}

```

Le script s'occupe de parser la réponse JSON et de mettre en forme les données pour l'afficher dans le terminal.
