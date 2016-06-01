# Qubes-vpn-support
Scripts for setting up secure VPN VMs in Qubes OS

Objectives:
-
* Provide a Fail-Closed yet transparent environment for secure VPN usage
* Isolate the VPN client within a dedicated Qubes Proxy VM (VPN VM)
* Prevent access to local VPN VM programs, from downstream and upstream
* Prevent accidental clearnet and tunnel access from within the VPN
* Support debian and fedora OS templates
* Future: Possibly add systray icon for VPN status and control

Setup
-
Create a Qubes Proxy VM with your preferred name and template (with openvpn installed) and using either sys-net or firewall as NetVM. Then add the Qubes-vpn-support files to /rw/config and customize the openvpn-client.ovpn config file.

All files should have root ownership:

`
cd /rw/config
chown root:root qubes-firewall-user-script rc.local
chown -R root:root openvpn
`

These files need +x permissions:

`chmod +x qubes-firewall-user-script rc.local openvpn/qubes-vpn-handler.sh
`

Re-start the VPN VM then see if the link works -- status pop-ups should appear. Then switch the 'test-up' parameter in the .ovpn config to 'up' and test normal operation.

Operation is simple: Just link App VMs to the VPN VM and start them.

Notes on qubes-firewall-user-script
-
This builds on the internal rules already set by Qubes 3.x firewall in a Proxy VM, and puts the VM in a very locked-down state for networking.

There are no hard-coded IPs and the OUTPUT controls VPN traffic by group ID. So if your VPN provider has dozens of IPs randomly-assigned via DNS or uses a client other than openvpn then no editing of the firewall script should be necessary.

Group ID can be easily assigned to VPN client with /rw/config/rc.local like this:
    groupadd -r qvpn
    sg qvpn -c 'openvpn --cd /rw/config/openvpn/ --config openvpn-client.ovpn \
    --daemon --writepid /var/run/openvpn/openvpn-client.pid'

...or you can add a "Group=qvpn" line to the Service section of your systemd openvpn-client.service file (see the example .service file).

Also, local traffic to and from tun0 and vif+ is disallowed, as well as incoming icmp packets.

Notes on qubes-vpn-handler.sh
-
This handler script is tested to work with openvpn v2.3.4, but should be easily adaptable to other VPN clients with one or two variable-handling changes.

The 'up' parameter adds DNS address translation without altering the local resolv.conf settings. This is intended as a privacy measure to prevent any inadvertant access by local (VPN VM) programs over the VPN tunnel.
