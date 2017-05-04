# Qubes-vpn-support
Scripts for setting up secure VPN VMs in Qubes OS

## Note: New template-installable version in `new-2` branch...

--

Objectives:
-
* Provide a **fail-closed** and transparent VPN environment that prevents leaks
* Isolate the VPN client within a dedicated Proxy VM; leverage Qubes architecture
* Easy setup: support server names, minimal file editing
  * Only VPN client config needs editing by user (openvpn); or client config & rc.local (others)
  * __Fewer opportunities for configuration errors__
* Prevent access to local VPN VM programs, from downstream and upstream
* Prevent accidental clearnet and tunnel access from within the VPN
* Support __Whonix__, Debian and Fedora OS templates
* Add conveniece and GUI features where sensible

---

Quickstart for OpenVPN
-
Create a proxyVM to run the VPN client, and launch a CLI in it. As root, copy Qubes-vpn-support/rw/config files into /rw/config. Then place your existing VPN config (*.ovpn) and related files in /rw/config/vpn and rename config file to `openvpn-client.ovpn`. Also populate the userpassword.txt file with your login info.

These files must be executable:
```
sudo chmod +x /rw/config/qubes-firewall-user-script /rw/config/rc.local /rw/config/vpn/qubes-vpn-ns
```

For testing, see Step 6 below.

Step-by-step for any VPN client (helps troubleshooting)
-
1. Create a Qubes Proxy VM with your preferred template and using either sys-net or sys-firewall as NetVM. The template must have your VPN client software installed *but not auto-starting* e.g. `sudo systemctl disable openvpn.service`.

In the new VM, do the following as root (use `sudo`)...

2. Place your existing VPN config (*.ovpn) and related files in /rw/config/vpn and rename config file to `openvpn-client.ovpn`. Place your VPN login credentials in the userpassword.txt file.
3. Test the connection with a command like `sudo openvpn --cd  /rw/config/vpn --config openvpn-client.ovpn`. You should be able to ping the remote network through the VPN before proceeding... though its unlikely you will have DNS at this point.

If you wish to test with DNS now, you can manually add your VPN's DNS addresses to `/etc/resolv.conf` and then run the `/usr/lib/qubes/qubes-setup-dnat-to-ns` script (make sure the VPN link is up first).

4. Copy Qubes-vpn-support/rw/config files into /rw/config and make scripts executable with:
```
sudo chmod +x /rw/config/qubes-firewall-user-script /rw/config/rc.local /rw/config/vpn/qubes-vpn-ns
```
5. Adding script directives to the ovpn is no longer necessary; Normally you can proceed directly to Step 6.

However, if your VPN service doesn't send DNS addresses via DHCP or if you need to set them another way, then assign the numbers you wish to use to the `vpn_dns` environment variable. For openvpn, add a setenv line to your config ovpn:
 ```
 setenv vpn_dns '1.2.3.4 6.7.8.9'
 ```
6. Test the VPN link again. Two ways to test and see if the link works:

  A) Manually run `sudo /rw/config/rc.local` before restarting. Firewall additions will not be in effect.

  B) Re-start the VPN VM. Firewall additions will be active.

  Either way, a status pop-up should appear letting you know you're connected.

Regular usage is simple: Just link other VMs to the VPN VM and start them!

Using clients other than OpenVPN
-
The main issue with using another client is how you run it. You can add a systemd .service file to /rw/config/vpn and adjust rc.local to use that instead. See the supplied openvpn-client.service file as an example of running under the `qvpn` group. You may also run it directly from rc.local like so (using opevpn as an example):
```
groupadd -rf qvpn
sleep 2s
sg qvpn -c 'openvpn --cd /rw/config/openvpn/ --config openvpn-client.ovpn \
--daemon --writepid /var/run/openvpn/openvpn-client.pid'
```

Passing the DNS addresses to `qubes-vpn-ns` is another issue: If your client doesn't automatically pass `foreign_option` vars in the same format as openvpn, then use the `vpn_dns` environment variable as explained in the script comments.

Since it is the job of a VPN vendor to focus tightly on __link__ security, you should be wary of VPN clients that try to manipulate iptables directly to secure the system's overall communicatios profile; It is unlikely they take Qubes' network topology into account. Normally, security should be added to a VPN setup from the OS or specialty scripts (like these) or by the admins and users themselves.

Notes on qubes-firewall-user-script
-
This builds on the internal rules already set by Qubes 3.x firewall in a Proxy VM, and puts the VM in a very locked-down state for networking.

There are no hard-coded IPs as traffic is controlled by group ID. So even if your VPN provider has dozens of IPs randomly-assigned via DNS or uses a client other than openvpn then no editing of the firewall script should be necessary.

Also, local traffic to and from tun0 and vif+ is disallowed, as well as incoming icmp packets.

Notes on qubes-vpn-ns
-
This handler script is tested to work with OpenVPN v2.3 and v2.4, but should be easily adaptable to other VPN clients with one or two variable-handling changes.

DNS addresses are automatically acquired from DHCP without altering the local resolv.conf settings. This is intended as a privacy measure to prevent any inadvertant access by local (VPN VM) programs over the VPN tunnel.

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
