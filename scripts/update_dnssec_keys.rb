#!/usr/local/bin/ruby
require 'rubygems'
require 'socket'
require 'epp' # gem install epp && gem install uuidtools
require 'pp'
require 'nokogiri'
require 'base64'

server = Epp::Server.new(
  :server => "drs.domain-registry.nl",
  :tag => ".....",
  :password => "....."
)

#
# Optional: Delete current keydata
#
# xml ='<?xml version="1.0" encoding="utf-8" standalone="no"?>
# <epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
#   <command>
#     <update>
#       <domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
#         <domain:name>' + ARGV[0] + '</domain:name>
#       </domain:update>
#     </update>
#     <extension>
#       <secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
#         <secDNS:rem>
#           <secDNS:all>true</secDNS:all>
#         </secDNS:rem>
#       </secDNS:update>
#     </extension>
#   </command>
# </epp>
# '
# raw_response = server.request(xml)
# response = Nokogiri::XML.parse(raw_response)

# unless response.xpath('//xmlns:epp/xmlns:response/xmlns:result').first['code'] =~ /1000/
#   puts "Remove keys failed..."
#   puts raw_response
#   exit 1
# end

#
# Add keys
#
xml = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <update>
      <domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>' + ARGV[0] + '</domain:name>
      </domain:update>
    </update>
      <extension>
      <secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
        <secDNS:add>
          <secDNS:keyData>
            <secDNS:flags>256</secDNS:flags>
            <secDNS:protocol>3</secDNS:protocol>
            <secDNS:alg>5</secDNS:alg>
            <secDNS:pubKey>' + ARGV[1] + '</secDNS:pubKey>
          </secDNS:keyData>
          <secDNS:keyData>
            <secDNS:flags>257</secDNS:flags>
            <secDNS:protocol>3</secDNS:protocol>
            <secDNS:alg>5</secDNS:alg>
            <secDNS:pubKey>' + ARGV[2] + '</secDNS:pubKey>
          </secDNS:keyData>
        </secDNS:add>
      </secDNS:update>
    </extension>
    <clTRID>500100-002</clTRID>
  </command>
</epp>
'

raw_response = server.request(xml)
response = Nokogiri::XML.parse(raw_response)

unless response.xpath('//xmlns:epp/xmlns:response/xmlns:result').first['code'] =~ /1000/
  puts "Add keys failed..."
  puts raw_response
  exit 1
end

print "OK"