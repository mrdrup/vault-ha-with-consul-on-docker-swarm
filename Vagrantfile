nodeCount = ENV['NODE_COUNT'].nil? ? 4 : ENV['NODE_COUNT'].to_i

$script = "yum install -y net-tools;"
nodeCount.times do |i|
  $script << "echo '192.168.250.#{i+11} swarm#{i+1}' >> /etc/hosts;"
end

Vagrant.configure("2") do |config|
  config.ssh.forward_agent = true
  config.ssh.insert_key    = false

  config.vm.provider :virtualbox do |v|
    v.customize ['guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold', 10000]
  end

  nodeCount.times do |i|
    config.vm.define "swarm#{i+1}" do |subconfig|
      subconfig.vm.box = "centos/7"
      subconfig.vm.hostname = "swarm#{i+1}"
      subconfig.vm.network :private_network, ip: "192.168.250.#{i+11}"
      subconfig.vm.provision "shell", inline: $script
    end
  end
end
