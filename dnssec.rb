#!/usr/bin/env ruby
require 'optparse'
require 'pp'

require File.join(File.dirname(__FILE__), 'dnssec', 'options')
require File.join(File.dirname(__FILE__), 'dnssec', 'list')
require File.join(File.dirname(__FILE__), 'dnssec', 'epp')
require File.join(File.dirname(__FILE__), 'plesk')

class DNSSec
  include Options
  include List
  include Epp

  DNSSEC_PATH = "/var/named/run-root/var/dnssec"
  ZONE_PATH = "/var/named/run-root/var"

  def initialize(args)
    make_sure_named_has_dnssec_enabled!
    parse_options(args)
    Dir.mkdir(DNSSEC_PATH) unless File.exists?(DNSSEC_PATH)
    execute_action
  end

  def execute_action
    case @action
      when :list then list_domains
      when :list_secure then list_domains(:secure)
      when :list_insecure then list_domains(:insecure)

      when :handle_plesk_event then sign_domain(ENV["NEW_DOMAIN_ALIAS_NAME"] || ENV["NEW_DOMAIN_NAME"])
      when :re_sign then re_sign
      when :sign then sign_domain(@domain)
    end
  end

  def make_sure_named_has_dnssec_enabled!
    bind_version = `/usr/sbin/named -v`
    if bind_version.gsub(/^.*?\s/,"").gsub(/\.\d-.*\n/,"").to_f < 9.4
      puts "dnssec.rb requires BIND 9.4 or newer to function. Please upgrade"
      puts "#{bind_version.gsub(/\n/,"")} to something newer..."
      exit
    end
    unless /dnssec-enable\s*yes/ =~ File.read("/var/named/run-root/etc/named.conf")
      puts "dnssec.rb requires BIND to have DNSSEC enabled. Please enable DNSSEC by adding"
      puts "dnssec-enable yes; to the options part of /var/named/run-root/etc/named.conf."
      exit
    end
  end

  def key_exists?(domain)
    Dir[File.join(DNSSEC_PATH, "K#{domain}*")].length > 0
  end

  def safe_exec(command)
    system(command) || raise("Command #{command} failed...")
  end

  def sign_domain(domain)
    if domain.nil? || domain == ""
      puts "No domain specified"
      exit
    end

    puts "Validating #{domain}..." ; STDOUT.flush

    unless domain_list.include?(domain)
      puts "We are not the pimary nameserver for Domain #{domain}..."
      exit
    end

    unless dnssec_capable?(domain)
      puts "Domain #{domain} is not DNSSEC capable (or not handled by SIDN?)"
      exit
    end

    new_keys = !key_exists?(domain)
    zsk = ksk = ""

    if new_keys
      puts "Generating keys for #{domain}..." ; STDOUT.flush

      # time to create some keys...
      zsk_file = `cd #{DNSSEC_PATH} && /usr/sbin/dnssec-keygen -r /dev/urandom -a RSASHA1 -b 1024 -n ZONE #{domain} | tail -1`
      ksk_file = `cd #{DNSSEC_PATH} && /usr/sbin/dnssec-keygen -r /dev/urandom -a RSASHA1 -b 2048 -n ZONE -f KSK #{domain} | tail -1`

      # 3 en 5 zijn protocol en algoritme
      zsk = File.read(DNSSEC_PATH + "/" + zsk_file.gsub(/\n/,".key")).gsub(/;.*?\n/, "").gsub(/^.*IN DNSKEY 256 3 5 /, "").gsub(/\n/, "")
      ksk = File.read(DNSSEC_PATH + "/" + ksk_file.gsub(/\n/,".key")).gsub(/;.*?\n/, "").gsub(/^.*IN DNSKEY 257 3 5 /, "").gsub(/\n/, "")

      puts "Generated keys:"
      puts "ZSK: #{zsk}"
      puts "KSK: #{ksk}"
      STDOUT.flush
    end

    begin
      safe_exec "cd #{ZONE_PATH} && cp #{domain} #{domain}.saved"
      safe_exec "cat #{DNSSEC_PATH}/K#{domain}.*.key >> #{ZONE_PATH}/#{domain}"
      safe_exec "cd #{DNSSEC_PATH} && /usr/sbin/dnssec-signzone -N INCREMENT -o #{domain} #{ZONE_PATH}/#{domain}"

      if new_keys
        raise "update_dnssec_keys failed" unless update_dnssec_keys(domain, zsk, ksk)
      end

      safe_exec "cd #{ZONE_PATH} && cp #{domain}.signed #{domain}"
      safe_exec "/sbin/service named reload"
      # `(echo "Subject: DNSSEC #{domain} geactiveerd";echo "From: info@lico.nl";echo "To: info@lico.nl";echo "DNSSEC voor #{domain} is geactiveerd... Gaarne even controleren op http://dnscheck.sidn.nl/ :)")|/usr/sbin/sendmail -t`
    rescue
      # `(echo "Subject: DNSSEC #{domain} mislukt";echo "From: info@lico.nl";echo "To: info@lico.nl";echo "DNSSEC voor #{domain} is mislukt!... Mogelijke info in: /var/log/dnssec.log")|/usr/sbin/sendmail -t`
      safe_exec "cd #{ZONE_PATH} && cp #{domain}.saved #{domain}"
      if new_keys
        `cd #{DNSSEC_PATH}/ && rm -rf K#{domain}.*`
        `cd #{DNSSEC_PATH}/ && rm -rf *set*#{domain}*`
      end
      raise $!
    end
  end

  def re_sign
    domain_list(:secure).each do |domain|
      puts "Re-signing #{domain}..."
      `cd #{DNSSEC_PATH} && /usr/sbin/dnssec-signzone -o #{domain} #{ZONE_PATH}/#{domain}`
      `cd #{ZONE_PATH} && cp #{domain}.signed #{domain}`
    end
    safe_exec "/sbin/service named reload"
  end
end

DNSSec.new(ARGV)
