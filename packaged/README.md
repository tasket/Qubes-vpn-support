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
on first line and password on second line. The openvpn config file should be renamed to 'openvpn-client.ovpn'.

2. (Optional) Test connection manually:
```
sudo openvpn --cd /rw/config/vpn --config openvpn-client.ovpn --auth-user-pass userpassword.txt
```
3. Enable anti-leak firewall script:
```
sudo ln -s /usr/lib/qubes/proxy-firewall-restrict /rw/config/qubes-firewall-user-script
```
4. Shutdown proxyVM.

5. Enable the service by "vpn-handler-openvpn" to Services tab in Qubes Manager / VM Settings.

6. Restart your new proxyVM

Regular usage is simple: Just link other VMs to the VPN VM and start them!

## Notes
This can be extended for tunnel/VPN software other than OpenVPN by adding appropriate unit extension files in /lib/systemd/system/qubes-vpn-handler.service.d folder.
