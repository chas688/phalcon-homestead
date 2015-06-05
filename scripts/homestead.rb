class Homestead
  def Homestead.configure(config, settings)
    # Configure The Box
    config.vm.box = "vinsonyung/debian-jessie-phalcon"
    config.vm.hostname = "Phalcon"

    # Configure A Private Network IP
    config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.10"
	
    # Configure A Few VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
      vb.name = 'Phalcon'
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--ostype", "Debian_64"]
    end

    # Configure Port Forwarding To The Box
    config.vm.network "forwarded_port", guest: 80, host: 8080
    config.vm.network "forwarded_port", guest: 443, host: 4438
    config.vm.network "forwarded_port", guest: 3306, host: 33068
    config.vm.network "forwarded_port", guest: 6379, host: 63798

    # Add Custom Ports From Configuration
    if settings.has_key?("ports")
      settings["ports"].each do |port|
        config.vm.network "forwarded_port", guest: port["guest"] || port["to"], host: port["host"] || port["send"], protocol: port["protocol"] ||= "tcp"
      end
    end

    # Configure The Public Key For SSH Access
    if settings.include? 'authorize'
      config.vm.provision "shell" do |s|
        s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
        s.args = [File.read(File.expand_path(settings["authorize"]))]
      end
    end

    # Copy The SSH Private Keys To The Box
    if settings.include? 'keys'
      settings["keys"].each do |key|
        config.vm.provision "shell" do |s|
          s.privileged = false
          s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
          s.args = [File.read(File.expand_path(key)), key.split('/').last]
        end
      end
    end

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"]
    end
	
    # Install All The Configured Nginx Sites
    settings["sites"].each do |site|
      config.vm.provision "shell" do |s|
		s.inline = "bash /vagrant/scripts/serve.sh $1 \"$2\" $3"
		s.args = [site["map"], site["to"], site["port"] ||= "80"]
      end
    end

    # Configure All Of The Configured Databases
    settings["databases"].each do |db|
      config.vm.provision "shell" do |s|
        s.path = "./scripts/create-mysql.sh"
        s.args = [db]
      end
    end

    # Update Composer On Every Provision
    config.vm.provision "shell" do |s|
      s.inline = "/usr/local/bin/composer self-update"
    end
	
  end
end
