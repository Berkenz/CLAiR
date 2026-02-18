.PHONY: up down build logs backend-logs db-shell migrate migration test-backend flutter-run flutter-test flutter-build-apk clean

up:
	docker-compose up -d

down:
	docker-compose down

build:
	docker-compose build

logs:
	docker-compose logs -f

backend-logs:
	docker-compose logs -f backend

db-shell:
	docker-compose exec db psql -U clair_user -d clair_db

migrate:
	docker-compose exec backend alembic upgrade head

migration:
	docker-compose exec backend alembic revision --autogenerate -m "$(msg)"

test-backend:
	docker-compose exec backend pytest -v

flutter-run:
	cd frontend && flutter run

flutter-test:
	cd frontend && flutter test

flutter-build-apk:
	cd frontend && flutter build apk

clean:
	docker-compose down -v --remove-orphans
