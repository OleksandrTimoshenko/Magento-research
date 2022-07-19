1. git clone git@github.com:OleksandrTimoshenko/Magento-research.git
2. cd ./Magento-research

## Local installation (outdated)
1. provide vars into ./install_magento.sh
2. copy script to your server
3. ssh username@server-ip
4. chmod +x install_magento.sh && sudo ./install magento.sh

## Docker installation
1. provide Magento username && password into ./docker/magento/auth.json.example
2. cp ./docker/magento/auth.json.example ./docker/magento/auth.json
3. cd ./docker
4. docker-compose up