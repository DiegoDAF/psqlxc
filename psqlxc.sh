#!/bin/bash

# 20200831 DAF Adaptation of https://github.com/isamert/dotfiles/blob/master/.scripts/getpassword
#              USAGE: bash  psqlxc.sh -t usms-db-main-root -h usms-db-main.cluster-ro-c6xs3p3jkysv.us-east-1.rds.amazonaws.com -d usms
#              -t must be unique on keepass
#              sudo apt install secret-tool keepassxc
#              $PASSWORD_STORE is defined in ~/.profile, it points to a .kdbx file

# This script gets the requested password from a keepass file.
# It uses gnome-keyring to get password for kdbx file.
# $KEYRING_ID is the name of password field for your keepass database
# in gnome-keyring.
# Save your keepass database password to keyring like this:
# secret-tool store --label=KeePassDbPassword name keepass

# Usage:
# getpassword "/path/to/password/entry"            → prints entry's password from keepass db
# getpassword "/path/to/password/entry" --username → prints only username
# getpassword "/path/to/password/entry" --dump     → prints both username and password
# getpassword --keepass                            → print PASSWORD_STORE's password
# getpass --list                                   → list PASSWORD_STORE's entries under
# getpass --list "Social"                          → list PASSWORD_STORE's entries under /Social
#
# $PASSWORD_STORE is defined in ~/.profile, it points to a .kdbx file


KEYRING_ID=keepass
PGPORT=5432

function trim {
    local var="${*:-$(</dev/stdin)}"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

while getopts t:U:h:d:g:p option
do
case "${option}"
in
g) GRUPO=${OPTARG};;
t) TITLE=${OPTARG};;
U) PGUSER=${OPTARG};;
h) PGHOST=${OPTARG};;
d) PGDATABASE=${OPTARG};;
p) PGPORT=${OPTARG};;  
esac
done

if [[ "$1" == "--keepass" ]]; then
    secret-tool lookup name "$KEYRING_ID"
    exit
elif [[ "$1" == "--list" ]]; then
    secret-tool lookup name keepass | keepassxc.cli ls "$PASSWORD_STORE" "$2"
    exit
fi

password=$(secret-tool lookup name "$KEYRING_ID")
info=$(echo "$password" | keepassxc.cli show --show-protected --quiet "$PASSWORD_STORE" "$TITLE")
PGUSER=$(echo "$info" | grep -i "username: " | cut -d: -f2 | trim)
PGPASSWORD=$(echo "$info" | grep -i "password: " | cut -d: -f2 | trim)

export PGHOST
export PGPORT
export PGDATABASE
export PGUSER
export PGPASSWORD

psql

PGPASSWORD=""
PGUSER=""
