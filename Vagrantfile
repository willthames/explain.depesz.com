# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network "private_network", ip: "192.168.44.55"

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  if Vagrant.has_plugin?("vagrant-puppet-install")
    config.vm.provision "puppet" do |puppet|
      puppet.options = "--verbose --debug"
      puppet.manifests_path = "."
      puppet.manifest_file = "explain.pp"
      puppet.facter = {
        "use_vagrant" => true
      }
    end
  else
    config.vm.provision "shell", path: "vagrant_bootstrap.sh"
  end
end
