Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.network :private_network, ip: "192.168.111.219"   
  config.vm.network :forwarded_port, guest: 80, host: 8088 # jetty or 192.168.111.219:80

  config.vm.provision "ansible" do |ansible|
      ansible.playbook = "deploy/vagrant.yml"
      ansible.inventory_path = "deploy/inventories/production"
      ansible.limit = 'all'
#      ansible.verbose = 'vvvv'
      ansible.extra_vars = {
        ansible_ssh_user: 'vagrant'
      }
  end
end
