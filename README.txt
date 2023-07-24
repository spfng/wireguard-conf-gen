#
# wg-mass by Spoofing <spoofing@spfng.com>
# wireguard config generator for multiple subnets and addresses
#
# quick start:
#
# $ chmod +x ./wg-mass.sh
# $ find $(./wg-mass.sh)
#
# example:
#
# $ env \
#       WG_NETWORK="192.168.1 192.168.2 192.168.3" \
#       WG_ADDRESS="1 2 3 4 5" \
#       ./wg-mass.sh
#
# it will generate configs for all these IPs on all these subnets
# and saves it under /tmp/wireguard.??? directory.
# just copy configs to /etc/wireguard and run "wg-quick up wg1"
#
# personally I like to have a few unused ("reserved") network interfaces
# for testing purposes or split services, users, VMs and other things.
#
# real world example:
#
# $ env \
#       WG_DIRECTORY="/etc/wireguard" \
#       WG_NETWORK="192.168.251 192.168.252 192.168.253 192.168.254 192.168.255" \
#       WG_ADDRESS="1 2 3 8 21 22 25 80 110" \
#       WG_SERVER_HOST="$(curl ifconfig.me/ip)" \
#       ./wg-mass.sh
#
# $ systemctl enable wg-quick@wg1
# $ systemctl enable wg-quick@wg2
# $ systemctl enable wg-quick@wg3
# $ systemctl enable wg-quick@wg4
# $ systemctl enable wg-quick@wg5
#
# now we have 192.168.[251-255].0/24 reserved tunnels for system services.
#
# $ env \
#       WG_DIRECTORY="/etc/wireguard"
#       WG_NETWORK="172.16.0 172.22.0" \
#       WG_ADDRESS="$(seq 1 50)" \
#       WG_SERVER_HOST="$(curl ifconfig.me/ip)" \
#       WG_CONFIG_COUNT_FROM="5" \
#       ./wg-mass.sh
#
# $ systemctl enable wg-quick@wg6
# $ systemctl enable wg-quick@wg7
#
# now have 172.16.0.[1-50]/24 for real users
# and also 172.22.0.[1-50]/24 for virtual machines
# first client in address list is always server. it can have 254 or other IP.
#
# so if you just needed a minimal working wireguard configuration then run:
#
# $ env \
#       WG_DIRECTORY="/etc/wireguard" \
#       WG_SERVER_HOST="$(curl ifconfig.me/ip)" \
#       ./wg-mass.sh
# $ systemctl enable --now wg-quick@wg1
# $ qrencode -t ansiutf8 < /etc/wireguard/client-192-168-0-2.conf
#
# scan QR-code from your mobile and stay connected. thats all.
#
