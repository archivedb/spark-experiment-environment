Vagrant.configure "2" do |configuration|
  indices = 0..2
  indices.each do |i|
    name = i == 0 ? "master" : "worker#{i}"
    configuration.vm.define name do |machine|
      machine.vm.hostname = name
      machine.vm.box = "ubuntu/bionic64"
      machine.vm.network "private_network", ip: "192.168.100.#{100+i}"
      machine.vm.provider "virtualbox" do |node|
        node.name = "h-#{name}"
        node.memory = 2560
        node.cpus = 2
      end
      if i == indices.last
        machine.vm.provision "ansible" do |ansible|
          ansible.playbook = "playbooks/playbook.yml"
          ansible.limit = "all"
        end
      end
    end
  end
end
