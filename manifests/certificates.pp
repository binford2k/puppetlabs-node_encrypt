# Class: node_encrypt::certificates
#
# This class distributes public certificates from your CA node to all compile
# server configuration. You should classify all your server nodes with this
# class, including the CA.
#
# It will set up a file mountpoint on the CA node, and then sync all agent public
# certificates to the $ssldir/certs directory on each compile server, where they
# can be used to encrypt secrets for agents.
#
# **Note**:
# If this is applied to nodes in a flat hierarchy (i.e., without a primary server),
# then all agents will have all public certificates synced. This is not a
# security risk, as public certificates are designed to be shared widely, but it
# is something you should be aware of.
#
# Parameters:
#
# [*ca_server*]
#  If the CA autodetection fails, then you can specify the $fqdn of the CA server here.
#
# [*sort_order*]
# If you've customized your HOCON-based `auth.conf`, set the appropriate sort
# order here. The default rule's weight is 500, so this parameter defaults to
# `300` to ensure that it overrides the default.
#
class node_encrypt::certificates (
  Optional[String[1]] $ca_server  = undef,
  Integer $sort_order = 300,
) {
  # Matches when the agent node is the CA itself.
  if $facts['networking']['fqdn'] in [$ca_server, $settings::ca_server] {
    # Set up file mountpoint to distribute the certs
    ini_setting { 'public certificates mountpoint path':
      ensure            => present,
      path              => $settings::fileserverconfig,
      section           => 'public_certificates',
      setting           => 'path',
      key_val_separator => ' ',
      value             => "${settings::ssldir}/ca/signed/",
    }

    puppet_authorization::rule { 'public certificates mountpoint whitelist':
      match_request_path   => '^/puppet/v3/file_(metadata|content)s?/public_certificates',
      match_request_type   => 'regex',
      match_request_method => 'get',
      allow                => '*',
      sort_order           => $sort_order,
      path                 => '/etc/puppetlabs/puppetserver/conf.d/auth.conf',
    }
  }
  # Sync all agent certificates so we can encrypt for them.
  # This will distribute the *public* certificates to all nodes, including other agents. This
  # is not a security risk, as that's how public certificates were designed to be used, but if
  # you'd like to limit this anyway, then simply ensure that this class is only enforced on the
  # CA and any servers in your infrastructure.
  else {
    file { "${settings::ssldir}/certs":
      ensure  => directory,
      recurse => true,
      purge   => true,
      ignore  => ['pe-internal-*', 'ca.pem'],
      source  => "puppet://${settings::ca_server}/public_certificates/", # lint:ignore:puppet_url_without_modules
    }
  }
}
