# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    #vagrant plugin install vagrant-env
    #config.env.enable
    config.vm.provider "virtualbox" do |v|
      v.memory = 6048
      v.cpus = 4
    end
    config.vm.define "server" do |machine|
      config.vm.network :public_network, ip: "192.168.0.160", bridge: "wlp0s20f3" #"wlp4s0"
      config.vm.box = "bento/ubuntu-20.04"
      #machine.vm.provision :ansible do |ansible|
      #  ansible.playbook = ENV["PLAYBOOK_NAME"]
      # ansible.verbose = 'vv'
      #end
    end
  end