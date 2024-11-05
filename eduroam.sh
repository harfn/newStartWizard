#!/bin/bash

# Variablen für Benutzername und Passwort
USER_NAME="gixo6309@uol.de"  # Ersetze mit deinem Benutzernamen
CERT_URL="https://uol.de/fileadmin/user_upload/itdienste/download/rootcert.crt"
CERT_PATH="$HOME/.certs/rootcert.crt"
INTERFACE="wlp4s0"  # Ersetze ggf. mit deiner WLAN-Schnittstelle
# Passwort abfragen
echo -n "Gib dein eduroam-Passwort ein: "
read -s PASSWORD
echo

# Erstelle das Verzeichnis für das Zertifikat
mkdir -p ~/.certs

# Lade das Zertifikat herunter
echo "Lade das Zertifikat herunter..."
wget -O "$CERT_PATH" "$CERT_URL"
if [ $? -ne 0 ]; then
    echo "Fehler beim Herunterladen des Zertifikats."
    exit 1
fi
echo "Zertifikat erfolgreich heruntergeladen nach $CERT_PATH"

# Erstelle und konfiguriere die eduroam-Verbindung
echo "Richte die eduroam-Verbindung ein..."
nmcli connection add type wifi ifname "$INTERFACE" con-name eduroam ssid eduroam
nmcli connection modify eduroam wifi-sec.key-mgmt wpa-eap
nmcli connection modify eduroam 802-1x.eap ttls
nmcli connection modify eduroam 802-1x.identity "$USER_NAME"
nmcli connection modify eduroam 802-1x.anonymous-identity "anonymous@uol.de"
nmcli connection modify eduroam 802-1x.ca-cert "$CERT_PATH"
nmcli connection modify eduroam 802-1x.domain-suffix-match "uol.de"
nmcli connection modify eduroam 802-1x.phase2-auth mschapv2
nmcli connection modify eduroam 802-1x.password "$PASSWORD"
nmcli connection modify eduroam connection.autoconnect yes

# Versuche, eine Verbindung herzustellen
echo "Verbinde mit eduroam..."
nmcli connection up eduroam
if [ $? -eq 0 ]; then
    echo "Erfolgreich mit eduroam verbunden."
else
    echo "Verbindung zu eduroam fehlgeschlagen."
fi

