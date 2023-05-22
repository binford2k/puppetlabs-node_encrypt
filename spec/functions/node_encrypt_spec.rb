require 'spec_helper'
require 'PuppetX/BinFord2k/node_encrypt'

describe 'node_encrypt' do
  let(:node) { 'testhost.example.com' }

  it {
    PuppetX::BinFord2k::NodeEncrypt.expects(:encrypt).with('foobar', 'testhost.example.com').returns('encrypted')
    is_expected.to run.with_params('foobar').and_return('encrypted')
  }

  if defined?(Puppet::Pops::Types::PSensitiveType::Sensitive)
    it {
      PuppetX::BinFord2k::NodeEncrypt.expects(:encrypt).with('foobar', 'testhost.example.com').returns('encrypted')
      is_expected.to run.with_params(Puppet::Pops::Types::PSensitiveType::Sensitive.new('foobar')).and_return('encrypted')
    }
  end
end
