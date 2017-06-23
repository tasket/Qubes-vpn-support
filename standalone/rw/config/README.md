# Qubes-vpn-support
Scripts for setting up secure VPN VMs in Qubes OS

## Note: New template-installable version in `new-2` branch...

--

Quickstart for OpenVPN
-
1. Create a proxyVM to run the VPN client, and launch a terminal in it.

2. As root, copy Qubes-vpn-support/rw/config files into /rw/config. Then place your existing VPN config (*.ovpn) and related files in /rw/config/vpn and rename config file to 'openvpn-client.ovpn'.

Next, populate the userpassword.txt file with your login info with username on first line and password on second line.

These files must be executable:
```
sudo chmod +x /rw/config/qubes-firewall-user-script /rw/config/rc.local /rw/config/vpn/qubes-vpn-ns
```

3. (Optional) Test the connection with a command like `sudo openvpn --cd  /rw/config/vpn --config openvpn-client.ovpn --auth-user-pass userpassword.txt`. You should be able to ping the remote network through the VPN before proceeding... though its unlikely you will have DNS at this point.

If you wish to test with DNS now, you can manually set your VPN's DNS addresses with:
```
export vpn_dns="<dns addresses>"
sudo /rw/config/vpn/qubes-vpn-ns up
```

Note, testing from a connected appVM is recommended because firewall rules can block internal (proxyVM) NS and ping requests. If the firewall script has not run yet (you haven't rebooted the VPN VM) then pinging from inside the VPN VM may work.

4. Restart your new VPN VM

Regular usage is simple: Just link other VMs to the VPN VM and start them!

