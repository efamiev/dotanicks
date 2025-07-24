PROJECT_NAME=dotanicks

# Для первой инициалиции феникс проекта через докер
docker-new-phx:
	docker-compose -f docker-compose.dev.yml run ${PROJECT_NAME} mix phx.new . --app ${PROJECT_NAME}

docker-new-phx-umbrella:
	docker-compose -f docker-compose.dev.yml run ${PROJECT_NAME} mix phx.new . --umbrella --no-ecto --no-mailer

# Для первого запуска локально
dev-bootstrap:
	docker-compose -f docker-compose.dev.yml run --rm ${PROJECT_NAME} mix setup

# Используется чтобы в дальнейшем можно было перейти внутрь контейнера
dev-up-container:
	docker-compose -f docker-compose.dev.yml up -d

dev-container-bash: dev-up-container
	docker-compose -f docker-compose.dev.yml exec ${PROJECT_NAME} bash

dev-start-server-iex: dev-up-container 
	docker-compose -f docker-compose.dev.yml exec ${PROJECT_NAME} iex -S mix phx.server

# Запуск зависимостей
dev-deps-start:
	docker-compose -f docker-compose.dev.yml up -d nginx

# dev-deps-start:
# 	docker-compose -f docker-compose.dev.yml up -d prometheus grafana nginx

dev-deps-stop:
	docker-compose -f docker-compose.dev.yml stop prometheus grafana nginx

# Локальный запуск
dev-app-start:
	set -a && source .env && set +a && mix deps.clean dotanicks --build && MIX_ENV=dev iex -S mix phx.server 

dev-app-format:
	set -a && source .env && set +a && mix format 

dotabuff-mock:
	MIX_ENV=test mix run -e "DotabuffMock.save_page(176_586_336)"
