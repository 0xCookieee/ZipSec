#!/bin/bash

# Tableau de couleur
BLUE='\e[1;36m'
RED='\e[31m'
NC='\e[0m'
GREEN='\e[32m'

# Message d'aide + utilisation du script
afficher_aide() {
  # Message d'aide avec exemple d'utilisation.
  echo -e "Ce script a pour utilité finale de chiffrer les fichiers clients et les archiver en ZIP automatiquement pour les entreprises travaillant avec des sous traitant ou seul"
  echo -e ""
  echo -e "Utilisation : ./zipsec.sh <fichier1> <fichier2> <fichier3> "
  echo -e ""
  echo -e "exemple : ./zipsec.sh rapport.pdf tableau.xlsx restitution.pptx"
  echo -e ""
}

# Affiche l'aide si aucun argument n’est entré
if [ $# -eq 0 ]; then
  afficher_aide
  echo -e "Aucun fichier en argument. Veuillez fournir au moins un nom de fichier à renommer."
  exit 0
fi

# Vérifiez les arguments de ligne de commande
if [ "$1" == "-h" ]; then
  afficher_aide
  exit 0
fi

if [ "$1" == "--help" ]; then
  afficher_aide
  exit 0
fi

# Ascii art
echo -e "███████╗██╗██████╗ ███████╗███████╗ ██████╗"
echo -e "╚══███╔╝██║██╔══██╗██╔════╝██╔════╝██╔════╝"
echo -e "  ███╔╝ ██║██████╔╝███████╗█████╗  ██║     "
echo -e " ███╔╝  ██║██╔═══╝ ╚════██║██╔══╝  ██║     "
echo -e "███████╗██║██║     ███████║███████╗╚██████╗"
echo -e "╚══════╝╚═╝╚═╝     ╚══════╝╚══════╝ ╚═════╝   Developped by 0xCookie"

# Webhook pour envoie du mot de passe
webhook_url="WEBHOOK SLACK"

# Génération d'un mot de passe de 12 caractères alphanumériques + symboles avec rendu aléatoire
password_length=12
char="AaBbCcDdEeFfGgHhJjKkMmNnPpQqRrSsTtUuVvWwXxYyZz123456789&~#{[\@*$+/}=!:;,."
pass=$(head /dev/urandom | base64 | tr -dc "$char" | head -c "$password_length")

# Tableau de choix des prestataires
echo -e ""
echo -e "${BLUE}Menu à choix pour le nom de l'entreprise :${NC}"
echo -e "${BLUE}1. A DEFINIR ${NC}"
echo -e "${BLUE}2. A DEFINIR ${NC}"
echo -e "${BLUE}3. A DEFINIR ${NC}"
echo -e "${BLUE}Autre prestataire ? Renseignez directement le nom${NC}"
echo -e ""

read -p "Veuillez choisir une entreprise 1/2/3/* : " choix_presta

case $choix_presta in
1)
  prestataire="MODIFIER"
  ;;
2)
  prestataire="A DEFINIR"
  ;;
3)
  prestataire="A DEFINIR"
  ;;
*)
  mission="$choix_presta"
  ;;
esac

echo ""

# Tableau de choix des type de test (mission)
echo -e "${BLUE}Type de test effectué :"
echo -e "${BLUE}1 - Externe${NC}"
echo -e "${BLUE}2 - Interne${NC}"
echo -e "${BLUE}3 - Applicatif${NC}"
echo -e "${BLUE}Autre type de test ? Entrez directement le type de test${NC}"
echo -e ""
read -p "Votre choix 1/2/3/* ? : " choix
echo -e ""

mission=""

case "$choix" in
1)
  mission="Externe"
  ;;
2)
  mission="Interne"
  ;;
3)
  mission="Applicatif"
  ;;
*)
  mission="$choix"
  ;;
esac

# Nom de l'entreprise pour l'archive ZIP
echo -e -n "Entrez le nom de l'entreprise destinataire de l'archive :"
read entreprise

date_format=$(date +%d-%m-%Y)

files_to_zip=()

echo ""

# Faire une boucle à partir du tableau d'argument
for nom_fichier_original in "$@"; do
  echo -e "${BLUE}Type de fichier : $nom_fichier_original${NC}"
  echo -e "${BLUE}1 - Renommer en Rapport${NC}"
  echo -e "${BLUE}2 - Renommer en Tableau de vulnérabilités${NC}"
  echo -e "${BLUE}3 - Renommer en Restitution${NC}"
  echo -e "${BLUE}Si votre mission n'apparait pas, entrez le type de mission${NC}"
  echo ""
  read -p "Votre choix 1/2/3/* ? : " choix_renommage

  # Check le nom du document
  case "$choix_renommage" in
  1)
    type_fichier="Rapport"
    ;;
  2)
    type_fichier="Tableau"
    ;;
  3)
    type_fichier="Restitution"
    ;;
  *)
    mission="$choix_renommage"
    ;;
  esac

  # Fonction renommage
  if [ -f "$nom_fichier_original" ]; then
    # Extraction de l'extension du nom de fichier
    extension="${nom_fichier_original##*.}"
    nouveau_nom_fichier="${type_fichier}_${mission}_${entreprise}_${prestataire}_${date_format}.${extension}"
    mv "$nom_fichier_original" "$nouveau_nom_fichier"
    echo -e "${GREEN} $nom_fichier_original renommé avec succès en $nouveau_nom_fichier ${NC}"
  else
    echo -e "${RED}Le fichier $nom_fichier_original n'existe pas.${NC}"
  fi
  files_to_zip+=("$nouveau_nom_fichier")
done

output="Livrables_${mission}_${entreprise}_${prestataire}_${date_format}.zip"
clear
# Vérification de sortie de l'archive
echo -e "Fichier de sortie : $output"
echo ""
echo -e "Création de l'archive ZIP..."
zip -q -e -P "$pass" "$output" "${files_to_zip[@]}"
if [ $? -eq 0 ]; then
  echo -e ""
  echo -e "${GREEN}Archive créer avec succès : $output ${NC}"
else
  echo -e "${RED}Échec de création de l'archive.${NC}"
  exit 1
fi
echo ''

# Requête d'envoi du mot de passe de l’archive
resultat_requete_slack=$(curl -s -X POST -H 'Content-type: application/json' --data '{"text":"Le nouveau mot de passe généré pour l’archive de l’audit '${entreprise}' de type '${mission}' et de la part de '${prestataire}' :     ```'$pass'```"}' "$webhook_url")

if [ "$resultat_requete_slack" = "ok" ]; then
  echo -e "${GREEN}Le mot de passe a été envoyé sur le canal Slack${NC}"
else
  echo -e "${RED}L'envoi du mot de passe sur le canal Slack a échoué${NC}"
fi
echo ''
echo "Voici le mot de passe de l'archive : $pass"

# Utilisation de du -k pour voir la taille du zip
taille=$(du -k "$output" | cut -f1)

# Convertion en méga-octets
taille_mo=$((taille / 1024))

# Limite de taille en méga-octets (par exemple, 20 Mo)
limite=20

# Initialisation du tableau message
message=""

if [ "$taille_mo" -lt "$limite" ]; then
  message="${RED}Le fichier $output est inférieur à ${limite} Mo et peut être envoyé en pièce jointe.${NC}"
else
  message="Le fichier $output est supérieur ou égal à ${limite} Mo. Mettez-le dans OneDrive."
  lien_telechargement="${RED}INSÉRER_LE_LIEN_ONEDRIVE_ICI${NC}"
fi

echo -e ""
echo -e "${message}"
echo ""

# Titre+corps de mail
if [[ "$mission" == "Externe" ]]; then
  mission_type="Pentest Externe"
elif [[ "$mission" == "Interne" ]]; then
  mission_type="Pentest Interne"
elif [[ "$mission" == "Applicatif" ]]; then
  mission_type="Pentest Applicatif"
else
  mission_type="$mission"
fi

titre_mail="Livrables - ${mission_type} - ${entreprise} / ${prestataire}"
corps_mail="Bonjour Messieurs,

La mission ${mission_type} de l'entreprise ${entreprise} est maintenant terminée.
Vous pouvez télécharger une archive chiffrée contenant :
"

for fichier in "${files_to_zip[@]}"; do
  corps_mail="${corps_mail}${fichier}
"
done

corps_mail="${corps_mail}
${lien_telechargement}
Pour déchiffrer l'archive, un mot de passe vous sera demandé. Pour le recevoir, merci de m'envoyer un SMS au [NUMERO DE TÉLÉPHONE].
Je vous remercie pour votre confiance et votre intérêt durant cet audit.
Bien cordialement,"

echo -e "${BLUE}Titre du mail :${NC}"
echo -e "$titre_mail"
echo -e ''
echo -e "${BLUE}Corps du mail :${NC}"
echo -e "$corps_mail"
echo -e ''
