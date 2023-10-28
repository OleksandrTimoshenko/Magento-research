include .env_local

export-etc-hosts:
	if ! grep -qF "$(VAGRANT_IP) $(DOMAIN_NAME)" /etc/hosts; then \
		echo "$(VAGRANT_IP) $(DOMAIN_NAME)" | sudo tee -a /etc/hosts; \
	fi

vagrant-up:
	VAGRANT_IP=$(VAGRANT_IP) vagrant up

setup-vagrant: export-etc-hosts vagrant-up

destroy-vagrant:
	VAGRANT_IP=$(VAGRANT_IP) vagrant destroy -f