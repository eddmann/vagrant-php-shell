Vagrant.configure("2") do |config|
    config.vm.box = "debian72"
    config.vm.box_url = "https://dl.dropboxusercontent.com/u/197673519/debian-7.2.0.box"
    config.vm.provision :shell, :path => "bootstrap.sh"
    config.vm.network :forwarded_port, guest: 80,   host: 8080 # web
    config.vm.network :forwarded_port, guest: 3306, host: 8181 # mysql
    config.ssh.forward_agent = true
    config.vm.provider :virtualbox do |vb|
        vb.customize [ "modifyvm", :id, "--memory", 512 ]
    end
end