require 'spec_helper_acceptance'

describe 'with empty nameservers list' do
  interface = 'eth0'
  service_name = case fact('osfamily')
                 when 'Debian'
                   'isc-dhcp-server'
                 else
                   'dhcpd'
                 end

  let(:pp) do
    <<-EOS
    $interface = $facts['networking']['interfaces']['#{interface}']

    class { 'dhcp':
      interfaces  => ['#{interface}'],
      nameservers => [],
    }

    dhcp::pool { "default subnet":
      network => $interface['network'],
      mask    => $interface['netmask'],
    }
    EOS
  end

  it_behaves_like 'a idempotent resource'

  describe file("/etc/dhcp/dhcpd.conf") do
    its(:content) { should_not match %r{option domain-name-servers } }
  end

  describe service(service_name) do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe port(67) do
    it { is_expected.to be_listening.on('0.0.0.0').with('udp') }
  end

  ip = fact("networking.interfaces.#{interface}.ip")
  mac = fact("networking.interfaces.#{interface}.mac")

  describe command("dhcping -c #{ip} -h #{mac} -s #{ip}") do
    its(:stdout) {
      pending('This is broken in docker containers')
      is_expected.to match("Got answer from: #{ip}")
    }
  end
end

describe 'with a non-empty nameservers list' do
  interface = 'eth0'
  service_name = case fact('osfamily')
                 when 'Debian'
                   'isc-dhcp-server'
                 else
                   'dhcpd'
                 end

  let(:pp) do
    <<-EOS
    $interface = $facts['networking']['interfaces']['#{interface}']

    class { 'dhcp':
      interfaces  => ['#{interface}'],
      nameservers => ['8.8.8.8', '8.8.4.4'],
    }

    dhcp::pool { "default subnet":
      network => $interface['network'],
      mask    => $interface['netmask'],
    }
    EOS
  end

  it_behaves_like 'a idempotent resource'

  describe file("/etc/dhcp/dhcpd.conf") do
    its(:content) { should match %r{option domain-name-servers 8.8.8.8, 8.8.4.4;} }
  end

  describe service(service_name) do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe port(67) do
    it { is_expected.to be_listening.on('0.0.0.0').with('udp') }
  end

  ip = fact("networking.interfaces.#{interface}.ip")
  mac = fact("networking.interfaces.#{interface}.mac")

  describe command("dhcping -c #{ip} -h #{mac} -s #{ip}") do
    its(:stdout) {
      pending('This is broken in docker containers')
      is_expected.to match("Got answer from: #{ip}")
    }
  end
end