#!/bin/bash

# Variablen für Benutzername und Zertifikat-URL

CERT_URL="https://uol.de/fileadmin/user_upload/itdienste/download/rootcert.crt"
CERT_PATH="$HOME/.certs/rootcert.crt"
INTERFACE="wlp4s0"  # Ersetze ggf. mit deiner WLAN-Schnittstelle

# Passwort abfragen
echo "Gib dein eduroam-Usernamen ein: "
echo  -n "Username (abcd1234):"
read  USER_NAME
echo

# Passwort abfragen
echo -n "Gib dein eduroam-Passwort ein: "
read  PASSWORD
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

# Prüfen, ob eine eduroam-Verbindung bereits existiert und ggf. löschen
EXISTING_UUIDS=$(nmcli -t -f UUID,NAME connection show | grep "^.*:eduroam$" | cut -d: -f1)
if [ -n "$EXISTING_UUIDS" ]; then
    echo "Bestehende eduroam-Verbindung(en) gefunden. Lösche die alte(n) Konfiguration(en)..."
    for UUID in $EXISTING_UUIDS; do
        nmcli connection delete uuid "$UUID"
    done
fi

# Erstelle und konfiguriere die eduroam-Verbindung direkt mit allen Details
echo "Richte die eduroam-Verbindung ein..."
nmcli connection add type wifi ifname "$INTERFACE" con-name eduroam ssid eduroam \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.identity "$USER_NAME" \
    802-1x.anonymous-identity "anonymous@uol.de" \
    802-1x.ca-cert "$CERT_PATH" \
    802-1x.domain-suffix-match "uol.de" \
    802-1x.phase2-auth mschapv2 \
    802-1x.password "$PASSWORD" \
    connection.autoconnect yes

# Versuche, eine Verbindung herzustellen
echo "Verbinde mit eduroam..."
nmcli connection up eduroam
if [ $? -eq 0 ]; then
    echo "Erfolgreich mit eduroam verbunden."
else
    echo "Verbindung zu eduroam fehlgeschlagen."
fi

