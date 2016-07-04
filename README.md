# Qubes-vpn-support
Scripts for setting up secure VPN VMs in Qubes OS

Objectives:
-
* Provide a **fail-closed** yet transparent VPN client that prevents leaks
* Isolate the VPN client within a dedicated Proxy VM; leverage Qubes architecture
* Easy setup: support server names, minimal file editing
  * Only VPN client config needs editing by user (openvpn); or client config & rc.local (others)
  * __Fewer opportunities for configuration errors__
* Prevent access to local VPN VM programs, from downstream and upstream
* Prevent accidental clearnet and tunnel access from within the VPN
* Support __Whonix__, Debian and Fedora OS templates
* Add conveniece and GUI features where sensible

Quickstart for openvpn
-
Create a proxyvm to run the VPN client. As root, place Qubes-vpn-support files and subfolders in /rw/config. Place your existing VPN config (*.ovpn) and related files in /rw/config/vpn. Then edit your VPN config to enable scripting (for openvpn, copy the `script-security`, `up` and `down` lines from the example ovpn to your own config) and rename it to `openvpn-client.ovpn`.

These files must be executable:
```
sudo chmod +x qubes-firewall-user-script rc.local vpn/qubes-vpn-handler.sh
```

Re-start the VPN VM to see if the link works -- a status pop-up should appear letting you know you're connected.

Step-by-step for any VPN client
-
1. Create a Qubes Proxy VM with your preferred template and using either sys-net or sys-firewall as NetVM. The template must have your VPN client software installed *but not auto-starting* e.g. `sudo systemctl disable openvpn.service`.
2. Create a /rw/config/vpn folder, place your VPN config file (openvpn-client.ovpn for example) there.
3. Test the connection with a command like `sudo openvpn --cd  /rw/config/vpn --config openvpn-client.ovpn`. You should be able to ping the remote network through the VPN before proceeding... though its unlikely you will have DNS at this point.

If you wish to test with DNS now, you can manually add your VPN's DNS addresses to `/etc/resolv.conf` and then run the `/usr/lib/qubes/qubes-setup-dnat-to-ns` script (make sure the VPN link is up first).

4. To enable automatic DNS, add the `qubes-vpn-handler.sh` script to /rw/config/vpn and make it executable with `sudo chmod +x /rw/config/vpn/qubes-vpn-handler.sh`. Then add script entries the VPN config file. For openvpn, use these:
```
script-security 2
up 'qubes-vpn-handler.sh up'
down 'qubes-vpn-handler.sh down'
```
If your VPN service doesn't send DNS addresses via DHCP or if you need to set them another way, then assign the numbers you wish qubes-vpn-handler to use to the `vpn_dns` environment variable. For openvpn, add a setenv line to your config ovpn:
```
setenv vpn_dns '1.2.3.4  6.7.8.9'
```
5. Test the VPN link again with the same command you used in step 3. You may need to restart the VM first to clear DNS settings from step 3 if you used them.
6. Add the `qubes-firewall-user-script` and `rc.local` files to /rw/config and make them both executable.


Operation is simple: Just link other VMs to the VPN VM and start them!

Using clients other than openvpn
-
The main issue with using another client is how you run it. You can add a systemd .service file to /rw/config/vpn and adjust rc.local to use that instead. See the supplied openvpn-client.service file as an example of running under the `qvpn` group. You may also run it directly from rc.local like so (using opevpn as an example):
```
groupadd -rf qvpn
sleep 2s
sg qvpn -c 'openvpn --cd /rw/config/openvpn/ --config openvpn-client.ovpn \
--daemon --writepid /var/run/openvpn/openvpn-client.pid'
```

Passing the DNS addresses to `qubes-vpn-handler.sh` is another issue: If your client doesn't automatically pass `foreign_option` vars in the same format as openvpn, then use the `vpn_dns` environment variable as explained in the script comments.

Since it is the job of a VPN vendor to focus tightly on __link__ security, you should be wary of VPN clients that try to manipulate iptables directly to secure the system's overall communicatios profile; It is unlikely they take Qubes' network topology into account. Normally, security should be added to a VPN setup from the OS or specialty scripts (like these) or by the admins and users themselves.

Notes on qubes-firewall-user-script
-
This builds on the internal rules already set by Qubes 3.x firewall in a Proxy VM, and puts the VM in a very locked-down state for networking.

There are no hard-coded IPs as traffic is controlled by group ID. So even if your VPN provider has dozens of IPs randomly-assigned via DNS or uses a client other than openvpn then no editing of the firewall script should be necessary.

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
