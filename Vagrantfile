Vagrant.configure("2") do |config|
    config.vm.box = "cent65"
    config.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v6.5.1/centos65-x86_64-20131205.box"
    config.vm.provision :shell, :path => "bootstrap.sh", :args => "nginx" # :args => "apache"
    config.vm.network :forwarded_port, guest: 80,   host: 8080 # web
    config.vm.network :forwarded_port, guest: 3306, host: 8181 # mysql
    config.vm.network :forwarded_port, guest: 1080, host: 8282 # mailcatcher
    config.ssh.forward_agent = true
    config.vm.provider :virtualbox do |vb|
        vb.customize [ "modifyvm", :id, "--memory", 512 ]
    end
end