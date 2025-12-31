#!/usr/bin/env bash
set -e

#############################################################
# CONFIGURATION GITHUB - Script d'automatisation
# Configure l'accès SSH à GitHub avec clé custom
#############################################################

# Couleurs
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
RESET='\033[0m'

# Fonctions utilitaires (définies en premier)
print_success() { echo -e "${GREEN}✅${RESET} $1"; }
print_warning() { echo -e "${YELLOW}⚠️${RESET}  $1"; }
print_error() { echo -e "${RED}❌${RESET} $1"; }
print_info() { echo -e "${CYAN}ℹ️${RESET}  $1"; }

#############################################################
# HEADER
#############################################################

echo -e "${CYAN}╔════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}   Configuration GitHub SSH          ${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════╝${RESET}\n"

print_info "Ce script va configurer votre accès GitHub via SSH"
echo ""

#############################################################
# COLLECTE DES INFORMATIONS
#############################################################

echo -e "${YELLOW}━━━ Configuration SSH ━━━${RESET}\n"

# Nom de la clé SSH
read -p "Nom de la clé SSH [id_github] : " SSH_KEY_NAME
SSH_KEY_NAME=${SSH_KEY_NAME:-id_github}

# Email pour la clé SSH
read -p "Email pour la clé SSH : " SSH_KEY_EMAIL
while [ -z "$SSH_KEY_EMAIL" ]; do
    echo -e "${RED}L'email ne peut pas être vide${RESET}"
    read -p "Email pour la clé SSH : " SSH_KEY_EMAIL
done

echo ""
echo -e "${YELLOW}━━━ Configuration Git ━━━${RESET}\n"

# Nom complet pour Git
read -p "Nom complet pour Git : " GIT_USER_NAME
while [ -z "$GIT_USER_NAME" ]; do
    echo -e "${RED}Le nom ne peut pas être vide${RESET}"
    read -p "Nom complet pour Git : " GIT_USER_NAME
done

# Email pour Git
read -p "Email pour Git [$SSH_KEY_EMAIL] : " GIT_USER_EMAIL
GIT_USER_EMAIL=${GIT_USER_EMAIL:-$SSH_KEY_EMAIL}

echo ""
echo -e "${CYAN}Récapitulatif :${RESET}"
echo -e "  ${BLUE}Clé SSH  :${RESET} $SSH_KEY_NAME"
echo -e "  ${BLUE}Email SSH:${RESET} $SSH_KEY_EMAIL"
echo -e "  ${BLUE}Nom Git  :${RESET} $GIT_USER_NAME"
echo -e "  ${BLUE}Email Git:${RESET} $GIT_USER_EMAIL"
echo ""

read -p "Confirmer ces informations ? (o/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo -e "${RED}Installation annulée${RESET}"
    exit 0
fi

#############################################################
# DÉBUT DE L'INSTALLATION
#############################################################

SSH_DIR="$HOME/.ssh"
SSH_KEY_PATH="$SSH_DIR/$SSH_KEY_NAME"
SSH_CONFIG="$SSH_DIR/config"
GITCONFIG_LOCAL="$HOME/.gitconfig.local"

#############################################################
# ÉTAPE 1 : Génération de la clé SSH
#############################################################

echo -e "\n${YELLOW}━━━ Étape 1/4 : Clé SSH ━━━${RESET}\n"

if [ -f "$SSH_KEY_PATH" ]; then
    print_warning "Clé SSH $SSH_KEY_NAME existe déjà"
    echo -e "  ${CYAN}Chemin :${RESET} $SSH_KEY_PATH"
else
    print_info "Création de la clé SSH : $SSH_KEY_NAME"
    
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    ssh-keygen -t ed25519 -C "$SSH_KEY_EMAIL" -f "$SSH_KEY_PATH" -N ""
    
    print_success "Clé SSH créée : $SSH_KEY_PATH"
fi

#############################################################
# ÉTAPE 2 : Configuration SSH
#############################################################

echo -e "\n${YELLOW}━━━ Étape 2/4 : Configuration SSH ━━━${RESET}\n"

if [ -f "$SSH_CONFIG" ] && grep -q "Host github.com" "$SSH_CONFIG"; then
    print_warning "Configuration GitHub existe déjà dans $SSH_CONFIG"
else
    print_info "Ajout de la configuration GitHub dans $SSH_CONFIG"
    
    cat >> "$SSH_CONFIG" <<EOF

# Configuration GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
EOF
    
    chmod 600 "$SSH_CONFIG"
    print_success "Configuration SSH ajoutée"
fi

#############################################################
# ÉTAPE 3 : Affichage de la clé publique
#############################################################

echo -e "\n${YELLOW}━━━ Étape 3/4 : Clé publique GitHub ━━━${RESET}\n"

print_info "Copiez cette clé publique pour l'ajouter sur GitHub :\n"

echo -e "${GREEN}════════════════════════════════════════${RESET}"
cat "${SSH_KEY_PATH}.pub"
echo -e "${GREEN}════════════════════════════════════════${RESET}\n"

echo -e "${CYAN}Ajouter cette clé sur GitHub :${RESET}"
echo "  1. Ouvrir : https://github.com/settings/ssh/new"
echo "  2. Title : $(hostname) - $SSH_KEY_NAME"
echo "  3. Key   : (coller la clé ci-dessus)"
echo "  4. Cliquer 'Add SSH key'"
echo ""

read -p "Appuyez sur ENTRÉE après avoir ajouté la clé sur GitHub..."

#############################################################
# ÉTAPE 4 : Test de connexion
#############################################################

echo -e "\n${YELLOW}━━━ Étape 4/4 : Test connexion GitHub ━━━${RESET}\n"

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    print_success "Connexion GitHub réussie !"
else
    print_error "Échec de la connexion GitHub"
    echo ""
    echo -e "${CYAN}Vérifications :${RESET}"
    echo "  1. Avez-vous bien ajouté la clé sur GitHub ?"
    echo "  2. Avez-vous cliqué sur 'Add SSH key' ?"
    echo "  3. Relancez : ssh -T git@github.com"
    exit 1
fi

#############################################################
# ÉTAPE 5 : Configuration Git locale
#############################################################

echo -e "\n${YELLOW}━━━ Configuration Git ━━━${RESET}\n"

if [ -f "$GITCONFIG_LOCAL" ]; then
    print_warning ".gitconfig.local existe déjà"
    echo ""
    echo -e "${CYAN}Contenu actuel :${RESET}"
    cat "$GITCONFIG_LOCAL"
else
    print_info "Création de .gitconfig.local"
    
    cat > "$GITCONFIG_LOCAL" <<EOF
[user]
    name = $GIT_USER_NAME
    email = $GIT_USER_EMAIL
EOF
    
    print_success ".gitconfig.local créé"
fi

echo ""
echo -e "${CYAN}Vérification configuration Git :${RESET}"
if command -v git >/dev/null 2>&1; then
    echo -e "  ${CYAN}Nom   :${RESET} $(git config user.name 2>/dev/null || echo 'non défini')"
    echo -e "  ${CYAN}Email :${RESET} $(git config user.email 2>/dev/null || echo 'non défini')"
fi

#############################################################
# RÉSUMÉ FINAL
#############################################################

cat << EOF

${GREEN}╔════════════════════════════════════════╗${RESET}
${GREEN}║${RESET}      Configuration terminée          ${GREEN}║${RESET}
${GREEN}╚════════════════════════════════════════╝${RESET}

${CYAN}Fichiers créés :${RESET}
  • $SSH_KEY_PATH (clé privée)
  • ${SSH_KEY_PATH}.pub (clé publique)
  • $SSH_CONFIG (configuration SSH)
  • $GITCONFIG_LOCAL (identité Git)

${CYAN}Prochaines étapes :${RESET}
  1. Cloner votre dépôt :
     ${YELLOW}git clone git@github.com:<username>/dotfiles.git${RESET}

  2. Installer les dotfiles :
     ${YELLOW}cd dotfiles && ./install.sh${RESET}

${CYAN}Tests rapides :${RESET}
  • Connexion GitHub : ${YELLOW}ssh -T git@github.com${RESET}
  • Config Git       : ${YELLOW}git config --list | grep user${RESET}

EOF
