# Qubes-vpn-support
Scripts for setting up secure VPN VMs in Qubes OS

Objectives:
-
* Provide a **fail-closed** yet transparent VPN tunnel in *qube* form
* Isolate the VPN client within a dedicated Proxy VM; leverage Qubes architecture
* Easy setup: support conventional server names, minimal file editing resulting in fewer opportunities for configuration errors
* Prevent access to local VPN VM programs, from downstream and upstream
* Prevent accidental clearnet and tunnel access from within the VPN
* Support Whonix, Debian and Fedora OS templates
* Add conveniece and GUI features where sensible

Setup
-
Create a Qubes Proxy VM with your preferred name and template (with openvpn installed) and using either sys-net or firewall as NetVM. Then add the Qubes-vpn-support files to /rw/config and customize the openvpn-client.ovpn config file.

All files should have root ownership:

```
sudo cd /rw/config
sudo chown root:root qubes-firewall-user-script rc.local
sudo chown -R root:root openvpn
```

These files need +x permissions:
```
sudo chmod +x qubes-firewall-user-script rc.local openvpn/qubes-vpn-handler.sh
```

Re-start the VPN VM then see if the link works -- status pop-ups should appear. Then switch the 'test-up' parameter in the .ovpn config to 'up' and test normal operation.

Operation is simple: Just link other VMs to the VPN VM and start them.

Notes on qubes-firewall-user-script
-
This builds on the internal rules already set by Qubes 3.x firewall in a Proxy VM, and puts the VM in a very locked-down state for networking.

There are no hard-coded IPs and the OUTPUT controls VPN traffic by group ID. So if your VPN provider has dozens of IPs randomly-assigned via DNS or uses a client other than openvpn then no editing of the firewall script should be necessary.

Group ID can be easily assigned to VPN client with /rw/config/rc.local like this:
```
groupadd -rf qvpn
sleep 2s
sg qvpn -c 'openvpn --cd /rw/config/openvpn/ --config openvpn-client.ovpn \
--daemon --writepid /var/run/openvpn/openvpn-client.pid'
```
...or you can add a "Group=qvpn" line to the Service section of your systemd openvpn-client.service file (see the included .service file and rc.local).

Also, local traffic to and from tun0 and vif+ is disallowed, as well as incoming icmp packets.

Notes on qubes-vpn-handler.sh
-
This handler script is tested to work with openvpn v2.3.4, but should be easily adaptable to other VPN clients with one or two variable-handling changes.

The 'up' parameter adds DNS address translation without altering the local resolv.conf settings. This is intended as a privacy measure to prevent any inadvertant access by local (VPN VM) programs over the VPN tunnel.

Roles
--
* The VPN VM is generally trusted. It is assumed its programs won't try to impersonate openvpn (send data via port 1194), for example.
* Everything outside the VPN VM and VPN server is essentially untrusted (from the VPN client's point of view): This means the sys-net, local router, ISP and downstream vms are potential threats. (This doesn't affect the users POV of whether individual appvms are trusted.)
* Everything that is downstream from VPN VM communicates through the VPN tunnel only.
* The purpose of the programs in the VPN VM is to support the creation of the VPN link. Their net access is either null or clearnet only; they should not send packets through the VPN tunnel and potentially get published.

Future
-
* Possibly add systray icon for VPN status and control
* Installation package for easier setup
