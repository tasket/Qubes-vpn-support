# Qubes VPN Support

## Packaged version for systemd (no rc.local used)

## Install in Qubes template, for preliminary testing:
```
# cd packaged
# cp -r qubes-vpn-handler.service* /lib/systemd/system
# systemctl enable qubes-vpn-handler.service
# cp proxy-firewall-restrict /usr/lib/qubes
# cp qubes-vpn-ns /usr/lib/qubes
# chmod +x /usr/lib/qubes/proxy-firewall-restrict /usr/lib/qubes/qubes-vpn-ns
```

## Setup proxyVM for use:
1. Add your VPN config files to /rw/config/vpn and test connection manually
2. `sudo ln -s /usr/lib/qubes/proxy-firewall-restrict /rw/config/qubes-firewall-user-script`
3. Shutdown proxyVM
4. Add "vpn-handler-openvpn" (or other service name corresponding to your VPN software) to Services (Qubes Manager / VM Settings)
5. Start proxyVM

## Notes
This can be extended for other tunnel/VPN software besides OpenVPN by adding appropriate unit extension files in /lib/systemd/system/qubes-vpn-handler.service.d folder.
