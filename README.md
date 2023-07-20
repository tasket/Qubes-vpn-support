# Qubes-vpn-support
Secure VPN VMs in [Qubes OS](https://www.qubes-os.org)


### Features
* Provides a **fail closed**, antileak VPN tunnel environment
* Isolates the tunnel client within a dedicated Proxy VM
* Prevents configuration errors
* Separate firewall VM not required

### Easy setup
* Simple install script; No file editing or IP numbers necessary
* Lets you 'drop in' configuration files from VPN service provider
* Flexible installation into template or to individual ProxyVMs

---

Quickstart setup guide
---

1. Create a ProxyVM using a template with VPN/tunnel software installed (i.e. OpenVPN). (In Qubes 4.0 a proxyVM is called an 'AppVM' with the `provides network` option enabled; this document will use the more descriptive 'ProxyVM' term...)

   Make a choice for the networking/netvm setting, such as `sys-net`.

   Next, add `vpn-handler-openvpn` to the ProxyVM's Settings / Services tab by
typing it into the top line and clicking the _plus_ icon. Do not add other network
services such as Network Manager.

2. Copy the VPN config files from your service provider to the ProxyVM's '/rw/config/vpn' folder, then copy or link the desired config to 'vpn-client.conf':

   ```
   sudo mkdir -p /rw/config/vpn
   cd /rw/config/vpn
   sudo unzip ~/ovpn-configs-example.zip
   sudo cp US_East.ovpn vpn-client.conf
   ```

   Note: This is a good point to test the connection. See the _Link Testing_ section below for tips.

3. Decide whether you want a template or ProxyVM-only installation. Copy the Qubes-vpn-support folder to the template or Proxy VM, then run install. You will be prompted for your VPN login credentials either in this step (ProxyVM) or next step (template):

   ```
   cd Qubes-vpn-support
   sudo bash ./install
   ```

4. If installed to a template, shutdown the templateVM then start the ProxyVM and finish setup with:

   ```
   sudo /usr/lib/qubes/qubes-vpn-setup --config
   ```

Restart the ProxyVM. This will autostart the VPN client and you should see a popup notification 'LINK IS UP'!

Regular usage is simple: Just link other VMs to the VPN VM and start them!

### Updating from prior versions

Download the new Qubes-vpn-support release from github to your VM as before, then run the `sudo bash ./install` command to reinstall. In a ProxyVM, username/password entry is performed last and can be skipped by pressing
Ctrl-C at the prompt. The updated VMs should then be shut down or restarted.

### Locating and downloading VPN config files

VPN configuration files are usually available from the VPN provider's support,
download or account pages as "Linux openvpn" or "Linux wireguard".
If they offer an "App", do not download this as it
won't work with Qubes-vpn-support.

Config download pages for popular VPN providers:
* [Mullvad](https://mullvad.net/en/account/#/openvpn-config/) (choose platform: Linux)
* [NordVPN](https://nordvpn.com/tutorials/linux/openvpn)

---

Technical notes
---

### Operating system support

Qubes-vpn-support is tested to run on Fedora 30, Debian 9 and 10 template-based VMs
under Qubes OS 4.0.1. It is further tested to operate in tandem with
[Whonix](https://www.whonix.org) gateway VMs to tunnel Tor traffic and/or tunnel over Tor.


### OpenVPN
* The OpenVPN version tested here is 2.4.x.

* It is assumed that 'tun' mode will be used by the VPN as this is by far the most common. The 'tap' mode may work, however it is currently untested.

* Routing details are determined by the VPN provider and can be viewed in the service log if required for troubleshooting. They will appear as references to "route" and "gateway".

### Wireguard VPN
* Experimental support for wireguard has been added. See the
wiki [for directions](https://github.com/tasket/Qubes-vpn-support/wiki/Wireguard-VPN-connections-in-Qubes-OS)
that include specific installation steps for wireguard in Debian along with Qubes-vpn-support.

### Link Testing and Troubleshooting

* Connections should be manually tested with a command like `sudo openvpn --cd  /rw/config/vpn --config vpn-client.conf --auth-user-pass userpassword.txt` _before_ the script 'install' step. This is a good idea because
it shows whether or not the basic link is working before Qubes-specific scripts
become a factor.

* After script installation, service commands such as `systemctl status qubes-vpn-handler` and `journalctl` may be used to monitor and troubleshoot connections started by the qubes-vpn-handler service.

* For manual DNS testing you can set DNS addresses in a CLI with:
  ```
  # Use 'up' for downstream VMs or 'test-up' for internal proxyVM tests
  sudo env vpn_dns="<dnsaddress1> <dnsaddress2>" /usr/lib/qubes/qubes-vpn-ns up
  ```

  Similarly, you can use `vpn_dns` to permanently override the DNS that your provider assigns. For openvpn use `setenv` in the config file like this:
  ```
  setenv vpn_dns 'dnsaddress1 dnsaddress2'

  ```

* You should be able to use `ping` and `traceroute` commands from a downstream AppVM without
issue after connecting. However, doing so from inside the VPN VM requires granting special
permission to the network with `sudo sg qvpn "command"`. (Also see *Firewall notes* for other
ways to permit outbound traffic.)

* Users have occasionally reported openvpn being unable to perform DNS lookups for the VPN provider's domain.
This may be due to the way Qubes passes DNS requests up through various netvm layers on their way to
the upstream network. Some workarounds that may improve DNS access are: 1. Populating /etc/resolv.conf with
the DNS address of your physical ISP; 2. Installing the `resolvconf` package; 3. Enabling egress as described
in the Firewall notes below.

### Tor/Whonix notes
Qubes-vpn-support can handle either Tor-over-VPN (configuring sys-whonix `netvm` setting to use VPN VM) or the reverse, VPN-over-Tor (configuring VPN VM `netvm` setting to use sys-whonix). The latter requires the VPN client to be configured for TCP instead of UDP protocol, and a different port number such as 443 may be required by your VPN provider; For openvpn this can all be specified with the `remote` directive in the config file.

### Using clients other than OpenVPN
The main issue with using another client is how you run it. In most cases, adding a conf file under qubes-vpn-handler.d to change the relevant variables and options should be sufficient. An experimental conf for wireguard is included and can be activated by removing '.example' from the filename; it has been tested with Mullvad.net.

Passing the DNS addresses to `qubes-vpn-ns` is another issue: If your client doesn't automatically pass `foreign_option` vars in the same format as openvpn, then on connection set the `vpn_dns` environment variable to one or more DNS addresses separated by a space. In the wireguard example this is accomplished by adding override functions to `wg-quick`.

Since it is the job of a VPN vendor to focus tightly on __link__ security, you should be wary of VPN clients that manipulate iptables or nftables in an attempt to secure the system's communications profile (i.e. prevent leaks); they probably don't take Qubes' unusual network topology into account in which case anti-leak would fail. Normally, security should be added to a VPN setup from the OS or specialty scripts (like these) or by the admins and users themselves. An exception to this is the LEAP bitmask client, which alters iptables with its own anti-leak rules that account for Qubes.

### Link security
A secure VPN service will use a certificate configuration, usually meaning `remote-cert-tls` is used in the openvpn config; This is the best way to protect against MITM attacks and ensure you are really connecting to your VPN service provider. Conversely, restricting access to particular addresses via the firewall is probably not going to substantially improve link security as IP addresses can be spoofed by an attacker.

### Firewall notes
The `proxy-firewall-restrict` script builds on the internal rules already set by Qubes firewall in a Proxy VM, and puts the VM in a very locked-down state for networking.

On Qubes 4.x this script is linked to /rw/config/qubes-firewall.d/90_tunnel-restrict and you can add a custom script in the qubes-firewall.d folder to include your own rules.

For userspace VPN protocols such as OpenVPN, traffic originating from the VPN VM is controlled by group ID of the
running process; only `qvpn` group is granted access. However, this restriction can be safely removed if necessary as it exists only to prevent accidental clearnet access from within the VPN VM and does not affect anti-leak rules for connected downstream VMs. Enable the Qubes service 'vpn-handler-egress' for the VPN VM to disable this group restriction.

ICMP packets are allowed for local traffic by default. If you think blocking ICMP is necessary you can enable
the Qubes service 'vpn-handler-no-icmp'. Note this does not affect downstream VM (forwarded) ICMP traffic; blocking this
can be done with the `qvm-firewall` tool.


### Basic concepts

* The VPN VM is generally trusted. It is assumed its other programs won't try to impersonate openvpn (send data via port 1194), for example.
* Everything outside the VPN VM and VPN server is essentially untrusted (from the VPN client's point of view): This means the sys-net, local router or Wifi access point, ISP and downstream VMs are potential threats. (This doesn't affect the users POV of whether individual appVMs or sites are trusted.)
* Everything that is downstream from VPN VM communicates through the VPN tunnel only.
* The purpose of the programs in the VPN VM is to support the creation of the VPN link. Their net access is either null or clearnet only; they should not send packets through the VPN tunnel and potentially get published.
* Configuration of the VPN client details (server address, protocols, etc) should be downloaded from the VPN provider's support page; the user can simply drop the config file into the /rw/config/vpn folder and rename it.

### Releases

v1.4.4, Dec. 2020:
  * Workaround for notification jam at start

v1.4.3, July 2019:
  * Misc compatibility fixes
  * Fix password character handling
  
v1.4.1, June 2019:
  * Qubes 4.0.1 support
  * Control over specific firewall restrictions
  * Better compatibility with MTU fragmentation detection

v1.4.0, Jan. 2019:
  * Anti-leak for IPv6
  * All DNS requests forced to chosen VPN DNS
  * Firewall integrity checked before connecting
  * Quicker re-connection
  * Supports passwordless cert authentication

v1.3 beta, July 2017

v1.0.2, June 2016

### Donations
* <a href="https://liberapay.com/tasket/donate"><img alt="Donate with Liberapay" src="images/lp_donate.svg" height=54></a>
* <a href="https://www.patreon.com/tasket"><img alt="Donate with Patreon" src="images/become_a_patron_button.png" height=50></a>

If you like Qubes-vpn-support or my other efforts, monetary contributions are welcome and can
be made through [Liberapay](https://liberapay.com/tasket/donate)
or [Patreon](https://www.patreon.com/tasket).

### See also:
[OpenVPN documentation](https://openvpn.net/index.php/open-source/documentation.html)

[Whonix - Tor networking in Qubes](https://www.qubes-os.org/doc/whonix/install/)

[Qubes VM hardening](https://github.com/tasket/Qubes-VM-hardening)

[Wyng incremental backup](https://github.com/tasket/wyng-backup)
