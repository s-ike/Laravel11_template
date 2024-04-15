DOCKER_CMD 	:= docker compose -f compose.yaml
APP_CMD 	:= ${DOCKER_CMD} exec app
WEB_CMD 	:= ${DOCKER_CMD} exec web
MYSQL_CMD 	:= ${DOCKER_CMD} exec db
ENV_FILE	:= ./.env

# 引数なしの`make`のみで実行 Laravelの.envがあれば`make up`、なければ`make init`
.PHONY: default
default:
	@if [ -e './src/.env' ]; then \
	make up; \
	else \
	make init; \
	fi

.PHONY:	init
init: ## 初期処理を行います。開発環境の作成を行います。
	git config core.ignorecase false
	cp src/.env.example src/.env
	mkdir -p ./data/db
	mkdir -p ./data/log/nginx
	mkdir -p ./data/log/mysql
	set -a && . ${ENV_FILE} && set +a && mkdir -p ./data/log/$${APP_NAME}
	${DOCKER_CMD} build
	@make up
	${APP_CMD} composer install
	${APP_CMD} php artisan key:generate
	${APP_CMD} php artisan storage:link
	${APP_CMD} chmod -R 777 storage bootstrap/cache
	@make fresh

.PHONY: up
up: ## 起動します。
	${DOCKER_CMD} up -d

.PHONY:	down
down: ## 停止します。
	${DOCKER_CMD} down

.PHONY:	d
d: down ## 停止します（downのエイリアス）。

.PHONY:	ps
ps: ## docker-compose ps
	${DOCKER_CMD} ps

.PHONY:	app
app: ## appコンテナに入ります。
	${APP_CMD} /bin/bash

.PHONY:	web
web: ## webコンテナに入ります。
	${WEB_CMD} /bin/bash

.PHONY:	fresh
fresh: ## データベースをリセットします。
	${APP_CMD} php artisan migrate:fresh --seed

.PHONY:	refresh
refresh: ## データベースをrefreshによりリセットします。
	${APP_CMD} php artisan migrate:refresh --seed

.PHONY:	info
info: ## プロジェクト内容を表示します。
	@set -a && . ${ENV_FILE} && set +a && echo "This is \"$${APP_NAME}\" project."

.PHONY:	help
help: info ## 各コマンドの説明を表示します。
	@echo ""
	@echo "Command list:"
	@echo ""
	@printf "\033[1;36m%-30s\033[1;37m %s\033[m\n" "[Sub command]" "[Description]"
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
