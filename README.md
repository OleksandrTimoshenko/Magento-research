## Vagrant installation
1. create `.env_local` file - `cp .env.example .env_local`
2. provide creds for downloading Magento with composer `MAGENTO_USER` and `MAGENTO_PASSWORD`
3. update other variables (optional)
4. `make setup-vagrant`
5. Go to trovided domain name
5. For delete vagrant environment - `make destroy-vagrant`

## Docker installation
1. provide Magento username && password into ./docker/magento/auth.json.example
2. cp ./docker/magento/auth.json.example ./docker/magento/auth.json
3. cd ./docker
4. docker-compose up
5. Go to [magetno](http://localhost)