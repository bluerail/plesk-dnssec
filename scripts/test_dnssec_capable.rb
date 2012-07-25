#!/usr/local/bin/ruby
require 'rubygems'
require 'socket'
require 'epp' # gem install epp && gem install uuidtools
require 'pp'
require 'nokogiri'

server = Epp::Server.new(
  :server => "drs.domain-registry.nl",
  :tag => ".....",
  :password => "....."
)

#
# Do we know about this domain?
#
xml = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">
  <command>
    <info>
      <domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd">
        <domain:name hosts="all">' + ARGV[0].to_s + '</domain:name>
      </domain:info>
    </info>
  </command>
</epp>
'

raw_response = server.request(xml)
response = Nokogiri::XML.parse(raw_response)

if response.xpath('//xmlns:epp/xmlns:response/xmlns:result').first['code'] =~ /1000/
  print "OK"
  exit 0
else
  print "FAIL"
  exit 1
end

