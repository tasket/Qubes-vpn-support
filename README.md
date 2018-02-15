# Qubes-vpn-support
Secure VPN VMs in Qubes OS

Features
-
* Provides a **fail-closed**, anti-leak VPN tunnel environment
* Isolates the tunnel client within a dedicated Proxy VM
* Isolates local VM programs from network

### Easy setup
  * Fully supports server names; IP addresses not necessary
  * Uses configuration files from VPN service provider
  * Less risk of configuration errors

### New in this version, v1.4 beta
  * Qubes 4.0 support (firewall)
  * Anti-leak for IPv6

### New in prior version, v1.3 beta
  * Simple install script; No file editing
  * Separate firewall not required (Qubes 'Deny except' works)
  * Flexible installation into template or to proxyVM-only

### Releases:
v1.4 beta, February 2018

v1.3 beta, July 2017

v1.0.2, June 2016

---

Quickstart setup guide
-
1. Create a proxyVM using a template with VPN/tunnel software installed (i.e. OpenVPN), then add `vpn-handler-openvpn` to the proxyVM's VM Settings / Services tab.

2. Transfer Qubes-vpn-support folder to the template or proxy VM of your choice, then run install. This will also prompt for your VPN login credentials either in this step (proxyVM) or next step (template):
```
cd Qubes-vpn-support
sudo bash ./install
```
3. If installed to a template, shutdown the templateVM then start the proxyVM and finish setup with:
```
sudo /usr/lib/qubes/qubes-vpn-setup --config
```

4. Copy the VPN config files from your service provider to the proxyVM's /rw/config/vpn folder, then copy or link the desired config to 'vpn-client.conf':
```
cd /rw/config/vpn
sudo unzip ~/ovpn-configs-example.zip
sudo ln -s US_East.ovpn vpn-client.conf
```

Restart the proxyVM. This will autostart the VPN client and you should see a popup notification 'LINK IS UP'!

Regular usage is simple: Just link other VMs to the VPN VM and start them!

---

Operating system support
-
Qubes-vpn-support is tested to run on Debian 9 and Fedora 26 template-based VMs under Qubes OS releases 3.2 and 4.0-rc4. It is further tested to operate in tandem with Whonix gateway VMs to tunnel Tor traffic and/or tunnel over Tor to enhance security and anonymity.

Note that upcoming VPN tunnel support packaged with Qubes OS will contain most
of the features in Qubes-vpn-support v1.4. Therefore, it is suggested most users
consider using that instead. This project will continue for people looking to
experiment with custom tweaks and new features.

Technical notes
-
### OpenVPN
The service config assumes the client will authenticate to the server using a username/password combination. It is also assumed that 'tun' mode will be used by the VPN as this is the most common.

Troubleshooting:
Some OpenVPN versions have difficulty with the 'persist tun' option; commenting it out can resolve some connection problems.

Connections can be directly tested with a command like `sudo openvpn --cd  /rw/config/vpn --config vpn-client.conf --auth-user-pass userpassword.txt` but using `systemctl status` and similar commands also work with normal auto-started connections. You should be able to use `ping` from a downstream appVM.

You can manually set your VPN's DNS addresses with:
```
export vpn_dns="<dns addresses>"
sudo /rw/config/vpn/qubes-vpn-ns up
```

Firewall __output__ restrictions can be temporarily disabled with `iptables -P OUTPUT ACCEPT` which will permit clearnet access to other programs in the VPN VM.

### Tor/Whonix notes
Qubes-vpn-support can handle either Tor-over-VPN (configuring sys-whonix `netvm` setting to use VPN VM) or the reverse, VPN-over-Tor (configuring VPN VM `netvm` setting to use sys-whonix). The latter requires the VPN client to be configured for TCP instead of UDP protocol, and a different port number may be needed; For openvpn this can all be specified with the `remote` directive in the ovpn config.

### Using clients other than OpenVPN
The main issue with using another client is how you run it. For standalone configs, you can add a systemd .service file to /rw/config/vpn and adjust rc.local to use that instead. See the supplied .service file as an example of running under the `qvpn` group. For template installations, adding a .conf file under /lib/systemd/system/qubes-vpn-handler.d is sufficient.

Passing the DNS addresses to `qubes-vpn-ns` is another issue: If your client doesn't automatically pass `foreign_option` vars in the same format as openvpn, then use the `vpn_dns` environment variable as explained in the script comments.

Since it is the job of a VPN vendor to focus tightly on __link__ security, you should be wary of VPN clients that try to manipulate iptables directly to secure the system's overall communicatios profile; It is unlikely they take Qubes' network topology into account. Normally, security should be added to a VPN setup from the OS or specialty scripts (like these) or by the admins and users themselves.

### General security
A secure VPN service will use a certificate configuration, usually meaning `remote-cert-tls` is used in the openvpn config; This is the best way to protect against MITM attacks and ensure you are really connecting to your VPN service provider. Conversely, restricting access to particular addresses via the firewall is probably not going to substantially improve link security as IP addresses can be spoofed by an attacker.

### Notes on qubes-firewall-user-script / proxy-firewall-restrict
This script builds on the internal rules already set by Qubes 3.x firewall in a Proxy VM, and puts the VM in a very locked-down state for networking. Adding your own iptables rules is most easily done by inserting them before the first `iptables` command.

The section that 'Corrects nameserver IPs' is new and not only sets up nat for DNS, but also corrects a Qubes issue that prevented the VPN VM from being used as a "Deny except" whitelist firewall.

Outgoing traffic is controlled by group ID. So even if your VPN provider has dozens of IPs randomly-assigned via DNS or uses a client other than openvpn then no editing of the firewall script should be necessary. However, this group-based control can be safely removed if necessary; it exists only to prevent accidental clearnet access from within the VPN VM and does not affect anti-leak rules for connected downstream VMs.

Also, local traffic to and from tun0 and vif+ is disallowed. However, the current version allows ICMP packets so if you think blocking these is necessary you can un-comment the ICMP section of the script.

### Notes on qubes-vpn-ns
This handler script is tested to work with OpenVPN v2.3 and v2.4, but should be easily adaptable to other VPN clients with one or two variable-handling changes.

DNS addresses are automatically acquired from DHCP without altering the local resolv.conf settings, so the VPN's DNS is normally only available to attached downstream VMs. This is intended as a privacy measure to prevent any inadvertant access by local (VPN VM) programs over the VPN tunnel.

### Basic concepts

* The VPN VM is generally trusted. It is assumed its programs won't try to impersonate openvpn (send data via port 1194), for example.
* Everything outside the VPN VM and VPN server is essentially untrusted (from the VPN client's point of view): This means the sys-net, local router, ISP and downstream VMs are potential threats. (This doesn't affect the users POV of whether individual appVMs are trusted.)
* Everything that is downstream from VPN VM communicates through the VPN tunnel only.
* The purpose of the programs in the VPN VM is to support the creation of the VPN link. Their net access is either null or clearnet only; they should not send packets through the VPN tunnel and potentially get published.
* Configuration of the VPN client details (server address, protocols, etc) should be downloaded from the VPN provider's support page; the user can simply drop the config file into the /rw/config/vpn folder and rename it.

Future
-
* Add systray icon for VPN status and control
* Explore support for other tunnel software: stunnel, wireguard, etc.

