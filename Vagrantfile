Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-20.04"
    master.vm.network :public_network, ip: ENV["VAGRANT_IP"], bridge: "wlp0s20f3" #"wlp4s0"
    master.vm.provision "file", source: "./install_magento.sh", destination: "install_magento.sh"
    master.vm.provision "file", source: "./.env_local", destination: ".env_local"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "6048"
      vb.cpus = "4"
    end
  end
  config.vm.provision "shell", run: "once",   path: "install_magento.sh"   # run in first time (or with --provision flag)
end