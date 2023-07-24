#!/bin/bash

test "$WG_DIRECTORY" || WG_DIRECTORY="$(mktemp -d -t wireguard.XXX)"

test "$WG_SERVER_HOST" || WG_SERVER_HOST="$(hostname -f)"
test "$WG_SERVER_PORT" || WG_SERVER_PORT="51820"

test "$WG_NETWORK" || WG_NETWORK="192.168.0"
test "$WG_ADDRESS" || WG_ADDRESS="1 2 3 4 5"

test "$WG_CONFIG_COUNT_FROM" || WG_CONFIG_COUNT_FROM="0"
test "$WG_CONFIG_SKIP_OR_RENEW" || WG_CONFIG_SKIP_OR_RENEW="RENEW" # TODO

wg_call_register_server () {
        local wg_interface_n="$1"
        local wg_interface="wg$wg_interface_n"
        local wg_server_ip="$2"

        local genkey="$(wg genkey)"
        local pubkey="$(wg pubkey <<< $genkey)"

        ServerPrivateKey="$genkey"
        ServerPublicKey="$pubkey"
        ServerConfigFile="$WG_DIRECTORY/$wg_interface.conf"

        if test "$wg_interface" = ""; then
                return 1
        fi

        if test "$wg_server_ip" = ""; then
                return 1
        fi

        wg_view_config "server-side" "$wg_interface" "$wg_server_ip"                                                   \
                "ServerPrivateKey:$ServerPrivateKey"                                                                   \
                "ServerPublicKey:$ServerPublicKey"                                                                     \
                "Address:$wg_server_ip/24"                                                                             \
                "ListenPort:$(($WG_SERVER_PORT + $wg_interface_n))"                                                    \
                >> "$ServerConfigFile"
}

wg_call_register_client () {
        local wg_interface_n="$1"
        local wg_interface="wg$wg_interface_n"
        local wg_client_ip="$2"

        local genkey="$(wg genkey)"
        local pubkey="$(wg pubkey <<< $genkey)"

        ClientPrivateKey="$genkey"
        ClientPublicKey="$pubkey"
        ClientConfigFile="$WG_DIRECTORY/client-${wg_client_ip//./-}.conf"

        if test "$wg_interface" = ""; then
                return 1
        fi

        if test "$wg_client_ip" = ""; then
                return 1
        fi

        wg_view_config "client-side" "$wg_interface" "$wg_client_ip"                                                   \
                "ClientPrivateKey:$ClientPrivateKey"                                                                   \
                "ClientPublicKey:$ClientPublicKey"                                                                     \
                "ServerPublicKey:$ServerPublicKey"                                                                     \
                "Address:$wg_client_ip/24"                                                                             \
                "Endpoint:$WG_SERVER_HOST:$(($WG_SERVER_PORT + $wg_interface_n))"                                      \
                "AllowedIPs:0.0.0.0/0"                                                                                 \
                "PersistentKeepalive:55"                                                                               \
                >> "$ClientConfigFile"

        wg_view_config "server-peer" "$wg_interface" "$wg_client_ip"                                                   \
                "ClientPublicKey:$ClientPublicKey"                                                                     \
                "AllowedIPs:$wg_client_ip/32"                                                                          \
                >> "$ServerConfigFile"

}

wg_view_config () {
        local wg_config_template="$1"
        local wg_interface="$2"
        local wg_client_ip="$3"

        local ServerPrivateKey
        local ServerPublicKey
        local ClientPrivateKey
        local ClientPublicKey
        local Address
        local Endpoint
        local AllowedIPs
        local PersistentKeepalive
        local ListenPort
        local DNS

        if test "$wg_interface" = ""; then
                return 1
        fi

        if test "$wg_client_ip" = ""; then
                return 1
        fi

        while test "$1"; do
                case "$1" in
                        "ServerPrivateKey:"*) ServerPrivateKey="${1#*:}" ;;
                        "ServerPublicKey:"*) ServerPublicKey="${1#*:}" ;;
                        "ClientPrivateKey:"*) ClientPrivateKey="${1#*:}" ;;
                        "ClientPublicKey:"*) ClientPublicKey="${1#*:}" ;;
                        "Address:"*) Address="${1#*:}" ;;
                        "Endpoint:"*) Endpoint="${1#*:}" ;;
                        "AllowedIPs:"*) AllowedIPs="${1#*:}" ;;
                        "PersistentKeepalive:"*) PersistentKeepalive="${1#*:}" ;;
                        "ListenPort:"*) ListenPort="${1#*:}" ;;
                        "DNS:"*) DNS="${1#*:}" ;;
                esac
                shift
        done

        if test "$wg_config_template" = "client-side"; then
                echo "[Interface]"
                echo "PrivateKey = $ClientPrivateKey"
                echo "Address = $Address"
                echo ""
                echo "[Peer]"
                echo "PublicKey = $ServerPublicKey"
                echo "Endpoint = $Endpoint"
                echo "AllowedIPs = $AllowedIPs"
                echo "PersistentKeepalive = $PersistentKeepalive"
                echo ""
        fi

        if test "$wg_config_template" = "server-side"; then
                echo "[Interface]"
                echo "PrivateKey = $ServerPrivateKey"
                echo "# PublicKey = $ServerPublicKey"
                echo "Address = $Address"
                echo "ListenPort = $ListenPort"
                echo ""
        fi

        if test "$wg_config_template" = "server-peer"; then
                echo "[Peer]"
                echo "PublicKey = $ClientPublicKey"
                echo "AllowedIPs = $AllowedIPs"
                echo ""
        fi
}

main () {
        local wg_interface
        local wg_interface_n
        local wg_client_ip
        local wg_server_ip

        local subnet
        local addr

        wg_interface_n="$WG_CONFIG_COUNT_FROM"

        for subnet in $WG_NETWORK; do
                wg_interface_n="$(($wg_interface_n + 1))"
                wg_interface="wg$wg_interface_n"
                wg_server_ip=""

                for addr in $WG_ADDRESS; do
                        wg_client_ip="$subnet.$addr"

                        if test "$wg_server_ip" = ""; then
                                wg_server_ip="$wg_client_ip"
                                wg_call_register_server "$wg_interface_n" "$wg_server_ip"
                        else
                                wg_call_register_client "$wg_interface_n" "$wg_client_ip"
                        fi
                done
        done

        echo "$WG_DIRECTORY"
}

main "$@"
