NAME		= inception
LOGIN		= vapoghos
DATA_DIR	= /home/$(LOGIN)/data
COMPOSE		= docker compose -f srcs/docker-compose.yml

all: setup up

setup:
	mkdir -p $(DATA_DIR)/db
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/backup

up: setup
	$(COMPOSE) up -d --build mariadb wordpress nginx

bonus: setup
	$(COMPOSE) up -d --build

bonus_cA:
	$(COMPOSE) --profile cadvisor up -d --build cadvisor

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps -a

clean: down
	docker system prune -af

fclean: clean
	-docker run --rm -v $(DATA_DIR):/data debian:bookworm-slim \
		rm -rf /data/db /data/wordpress /data/backup
	sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all setup up bonus bonus_cA down stop start restart logs ps clean fclean re
