DOCKER_CMD 	:= docker compose -f compose.yaml
APP_CMD 	:= ${DOCKER_CMD} exec app
WEB_CMD 	:= ${DOCKER_CMD} exec web
DB_CMD 		:= ${DOCKER_CMD} exec db
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
	cp .env.example ${ENV_FILE}
	cp src/.env.example src/.env
	cat src/.env >> ${ENV_FILE}
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

.PHONY: cache
cache: ## Laravelのキャッシュを作成します。
	${APP_CMD} composer dump-autoload -o
	${APP_CMD} php artisan optimize

.PHONY: clear
clear: ## Laravelのキャッシュクリアを実行します。
	${APP_CMD} composer clear-cache
	${APP_CMD} php artisan optimize:clear

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

.PHONY:	destroy
destroy: ## コンテナ、イメージ、ボリューム、ネットワークを削除します。
	@read -p "Are you sure? [y,N]:" ans; \
	if [ "$$ans" = y ]; then  \
	${DOCKER_CMD} down --rmi all --volumes --remove-orphans; \
	fi

.PHONY:	app
app: ## appコンテナに入ります。
	${APP_CMD} /bin/bash

.PHONY:	web
web: ## webコンテナに入ります。
	${WEB_CMD} /bin/bash

.PHONY:	db
db: ## dbコンテナに入ります。
	${DB_CMD} /bin/bash

.PHONY:	sql
sql: ## dbコンテナのデータベースに入ります。
	set -a && . ${ENV_FILE} && set +a && ${DB_CMD} mysql -h 127.0.0.1 -u $${DB_USERNAME} -p$${DB_PASSWORD} $${DB_DATABASE}

.PHONY:	migrate
migrate: ## データベースの更新を行います。
	${APP_CMD} php artisan migrate

.PHONY:	rollback
rollback: ## データベースのロールバックを行います。
	${APP_CMD} php artisan migrate:rollback

.PHONY:	fresh
fresh: ## データベースをリセットします。
	${APP_CMD} php artisan migrate:fresh --seed

.PHONY:	refresh
refresh: ## データベースをrefreshによりリセットします。
	${APP_CMD} php artisan migrate:refresh --seed

.PHONY:	seed
seed: ## データベースへシードを実行します。
	${APP_CMD} php artisan db:seed

.PHONY:	tinker
tinker: ## tinkerを実行します。
	${APP_CMD} php artisan tinker

.PHONY:	install
install: ## composer install.
	${APP_CMD} composer install

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
