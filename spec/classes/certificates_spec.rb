require 'spec_helper'
require 'PuppetX/BinFord2k/node_encrypt'

describe 'node_encrypt::certificates' do
  before(:each) do
    Puppet[:ca_server] = 'ca.example.com'
    Puppet[:confdir]   = '/etc/puppetlabs/puppet'
    Puppet[:ssldir]    = '/etc/puppetlabs/puppet/ssl'
  end

  context 'when run on a Puppet 5.x CA' do
    # Test case don't work? Comment it, yo! http://i.imgur.com/ki41AH1.gifv

    let(:node) { 'ca.example.com' }
    let(:facts) do
      {
        fqdn: 'ca.example.com',
      servername: 'ca.example.com',
      puppetversion: '5.3.5',
      }
    end

    it {
      is_expected.to contain_ini_setting('public certificates mountpoint path').with({
                                                                                       ensure: 'present',
        path: '/etc/puppetlabs/puppet/fileserver.conf',
        value: '/etc/puppetlabs/puppet/ssl/ca/signed/',
                                                                                     })
    }

    it {
      is_expected.to contain_puppet_authorization__rule('public certificates mountpoint whitelist').with({
                                                                                                           match_request_path: '^/puppet/v3/file_(metadata|content)s?/public_certificates',
        match_request_type: 'regex',
        allow: '*',
        sort_order: 300,
        path: '/etc/puppetlabs/puppetserver/conf.d/auth.conf'
                                                                                                         })
    }

    it { is_expected.not_to contain_file('/etc/puppetlabs/puppet/ssl/certs') }
  end

  context 'when run on a compile server' do
    let(:node) { 'compile1.example.com' }
    let(:facts) do
      {
        fqdn: 'compile1.example.com',
      servername: 'ca.example.com',
      }
    end

    it { is_expected.not_to contain_ini_setting('public certificates mountpoint path') }
    it { is_expected.not_to contain_ini_setting('public certificates mountpoint whitelist') }

    it {
      is_expected.to contain_file('/etc/puppetlabs/puppet/ssl/certs').with({
                                                                             ensure: 'directory',
        source: 'puppet://ca.example.com/public_certificates/',
                                                                           })
    }
  end

  context 'when run on a tier3 agent' do
    let(:node) { 'agent.example.com' }
    let(:facts) do
      {
        fqdn: 'agent.example.com',
      servername: 'compile01.example.com',
      }
    end

    it { is_expected.not_to contain_ini_setting('public certificates mountpoint path') }
    it { is_expected.not_to contain_ini_setting('public certificates mountpoint whitelist') }
  end
end
