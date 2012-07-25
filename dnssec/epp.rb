class DNSSec
  module Epp
    # Validates if DNSSec could be turned on for a domain
    def dnssec_capable?(domain)
      `ssh admin@whitelisted_server "plesk-dnssec/scripts/test_dnssec_capable.rb #{domain}"` == "OK"
    end

    # Uploads DNSSec ZSK and KSK key to the appropiate registry
    def update_dnssec_keys(domain, zsk, ksk)
      `ssh admin@whitelisted_server 'plesk-dnssec/scripts/update_dnssec_keys.rb #{domain} \"#{zsk}\" \"#{ksk}\"'` == "OK"
    end
  end
end