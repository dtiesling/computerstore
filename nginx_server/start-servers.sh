#!/usr/bin/env bash
# Simple script that handles the startup of the servers. The first argument is the
# hostname of the postgres instance to wait for.

# Do any needed database migrations.
cd /apps/computerstore/django_app
python3 ./manage.py migrate --no-input

# Start Django server.
gunicorn -c python:gunicornconfig app.wsgi &

# Start Next.js server.
cd /apps/computerstore/nextjs_app
npm run start &

# Start nginx server
nginx -g "daemon off;"