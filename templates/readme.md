# Basis-Ansible-Konfiguration fuer Baikonur-Netzwerk
Rollen-Definitionen zum Einrichten des Heimnetzwerkes

## Rolle "initial_05_network"
Standard-Einrichtungsschritte für jeden Host: Einrichtung der Netzwerk-Parameter.

## Verzeichnis "templates"
Jinja2-Templates, welche von der Rolle benötigt werden könnten

## Templates:
* **network/30-ansible.cfg.j2:**
* **network/35-serveNet-ansible.cfg.j2:**
* **network/dhcpcd.exit-hook.j2:**
* **network/wpa_supplicant.conf.j2:**
