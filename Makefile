FIG=docker-compose
RUN=$(FIG) run --rm
EXEC=$(FIG) exec
CONSOLE=php bin/console

.PHONY: help start stop build up reset config db-diff db-migrate vendor reload test assets assets-prod

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  reload   clear cache, reload database schema and load fixtures (only for dev environment)"

##
## Docker
##---------------------------------------------------------------------------

start:          ## Install and start the project
start: build up

stop:           ## Remove docker containers
	$(FIG) kill
	$(FIG) rm -v --force

reset:          ## Reset the whole project
reset: stop start

build:
	$(FIG) build

up:
	$(FIG) up -d

vendor:           ## Vendors
	$(RUN) php yarn install
	$(RUN) php composer install
	$(RUN) php $(CONSOLE) avanzu:admin:fetch-vendor

config:        ## Init files required
	cp -n .env.dist .env
	cp -n docker-compose.override.yml.dist docker-compose.override.yml

install:          ## Install the whole project
install: config start vendor reload

clear:          ## Remove all the cache, the logs, the sessions and the built assets
	$(EXEC) php rm -rf var/cache/*
	$(EXEC) php rm -rf var/logs/*

##
## DB
##---------------------------------------------------------------------------

db-diff:      ## Generation doctrine diff
	$(RUN) php $(CONSOLE) doctrine:migrations:diff

db-migrate:   ## Launch doctrine migrations
	$(RUN) php $(CONSOLE) doctrine:migrations:migrate -n

## Others
reload: clear reload-db fixtures

reload-db:
	$(RUN) php $(CONSOLE) doctrine:database:drop --force
	$(RUN) php $(CONSOLE) doctrine:database:create
	$(RUN) php $(CONSOLE) doctrine:migrations:migrate -n

fixtures:
	$(RUN) php $(CONSOLE) doctrine:fixtures:load -n

assets:   ## Launch doctrine migrations
	$(RUN) php $(CONSOLE) assets:install web --symlink
	$(RUN) php yarn run encore dev

assets-prod:   ## Launch doctrine migrations
	$(RUN) php $(CONSOLE) assets:install web --symlink --env=prod
	$(RUN) php yarn run encore production

test:
	$(RUN) php vendor/phpunit/phpunit/phpunit

php-cs-fixer:
	$(RUN) php bin/php-cs-fixer fix

