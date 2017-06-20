# Qubes VPN Support

Packaged version for systemd (no rc.local used)

## Install in Qubes template, for testing:
```
cd Qubes-vpn-support/packaged
sudo bash ./install
```
...then shutdown template VM.

## Setup a proxyVM for openvpn use:
1. Add your VPN config files to /rw/config/vpn and don't forget to add 'userpassword.txt' with your username
on first line and password on second line.
2. (Optional) Test connection manually:
```
sudo openvpn --cd /rw/config/vpn --config openvpn-client.ovpn --auth-user-pass userpassword.txt
```
3. Enable anti-leak firewall script:
```
sudo ln -s /usr/lib/qubes/proxy-firewall-restrict /rw/config/qubes-firewall-user-script
```
4. Shutdown proxyVM.
5. Add "vpn-handler-openvpn" to Services tab in Qubes Manager / VM Settings.
6. Start proxyVM and connect appVMs to it.

## Notes
This can be extended for other tunnel/VPN software besides OpenVPN by adding appropriate unit extension files in /lib/systemd/system/qubes-vpn-handler.service.d folder.
