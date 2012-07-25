#!/bin/bash
cd /usr/local/plesk-dnssec && ruby ./dnssec.rb $@ >> /var/log/dnssec.log 2>&1
