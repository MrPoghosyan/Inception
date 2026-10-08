NAME		= inception
LOGIN		= vapoghos
DATA_DIR	= /home/$(LOGIN)/data

COMPOSE		= docker compose -f srcs/docker-compose.yml
PROFILE		= --profile cadvisor

MANDATORY	= mariadb wordpress nginx
IMAGES		= mariadb wordpress nginx redis ftp static-site adminer backup

.PHONY: all setup up bonus bonus_cA down start stop restart logs ps clean fclean re

all: up

setup:
	mkdir -p $(DATA_DIR)/db
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/backup

up: setup
	$(COMPOSE) up -d --build $(MANDATORY)

bonus: setup
	$(COMPOSE) up -d --build

bonus_cA: setup
	$(COMPOSE) $(PROFILE) up -d --build cadvisor

down:
	$(COMPOSE) $(PROFILE) down --remove-orphans

start:
	$(COMPOSE) $(PROFILE) start

stop:
	$(COMPOSE) $(PROFILE) stop

restart:
	$(COMPOSE) $(PROFILE) restart

logs:
	$(COMPOSE) $(PROFILE) logs -f

ps:
	$(COMPOSE) $(PROFILE) ps -a

clean: down
	docker image prune -f
	docker builder prune -f

fclean: clean
	sudo rm -rf $(DATA_DIR)
	-docker rmi -f $(IMAGES)

re: fclean all
