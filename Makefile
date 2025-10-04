up:
	docker compose -f srcs/docker-compose.yml --env-file srcs/.env up --build -d

down:
	docker compose -f srcs/docker-compose.yml down

re: down up

logs:
	docker compose -f srcs/docker-compose.yml logs -f

clean:
	docker compose -f srcs/docker-compose.yml down -v
	docker system prune -af --volumes

ps:
	docker compose -f srcs/docker-compose.yml ps

.PHONY: up down re logs clean ps

