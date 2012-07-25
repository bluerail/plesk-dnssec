# What?

Plesk does not include support for DNSSEC (yet)... until now! This library adds support to Plesk with some simple scripts. When these scripts get called by the Plesk Event Manager they'll sign the zone and replace the unsigned file with the signed one.

Tested with:

* Plesk 10.4
* Plesk 11.0.9

# REQUIREMENTS

These scripts require:

* Ruby
* Rubygems
* MySQL2 gem
* BIND >= 9.4

## BIND97 on CentOS 5

CentOS 5 ships with Bind 9.3. A package called bind97 is available, but not available as an update. Remove the previous version of bind without dependencies and install the new one. Notes:

* you might need to add the ip of a mirror to your hosts file to install bind97 when no bind is installed (e.g. 192.87.102.43 ftp.nluug.nl)
* Be sure to revert your /etc/sysconfig/named.rpmsave. This file most likely contains something like:
    ROOTDIR="/var/named/run-root"
    OPTIONS="-c /etc/named.conf -u named"

# INSTALLATION

  cd /usr/local && git clone https://github.com/bluerail/plesk-dnssec.git

Test the tools:

* /usr/local/plesk-dnssec/dnssec.rb --list-insecure

Add command `/usr/local/plesk-dnssec/dnssec.sh --handle-plesk-event --event dns_zone_updated` to the following events in Plesk:
                                      
* Default domain, alias DNS zone updated
* Default domain, DNS zone updated
* Domain alias DNS zone updated
* Domain DNS zone updated
* Subdomain DNS zone updated

Add cron:

  0 6 * * 1 /usr/local/plesk-dnssec/dnssec.sh --re-sign
                                      
# PROBLEMS

Analyze /var/log/dnssec.log...

Some common problems:

* Ruby can't be found in PATH

# TODO

1. DNSSec::Epp uses some shell scripts to perfom its actions due to ip-whitelisting. The shell scripts included only apply DNSSEC for domains registered at SIDN. A future version should be capable of handling more registries. Pull requests welcome here!
2. The re-sign script has not been tested thoroughly
