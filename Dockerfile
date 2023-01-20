FROM nginx:mainline
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get -y update && apt-get -y upgrade && apt-get -y install python3 python3-pip nodejs libpq-dev python-dev

# Copy the nextjs frontend app files into the container, install dependencies and build it.
COPY nextjs_app /apps/computerstore/nextjs_app
WORKDIR /apps/computerstore/nextjs_app
RUN npm install -g npm@latest
RUN npm cache verify
RUN npm run build

# Install Python dependencies and copy the Django backend application files into the container.
COPY django_app/Pipfile /apps/computerstore/
COPY django_app/Pipfile.lock /apps/computerstore/
WORKDIR /apps/computerstore
RUN pip3 install --upgrade pip &&\
    pip3 install pipenv &&\
    pipenv install --deploy --system
COPY django_app /apps/computerstore/django_app
WORKDIR /apps/computerstore/django_app
RUN python3 ./manage.py collectstatic --no-input

# Copy the Nginx configuration file into the default location.
COPY nginx_server/nginx.conf /etc/nginx/conf.d/default.conf

# Set the entrypoint to run a script that will run the frontend and backend application
# servers. The main nginx server that is exposed to outside world runs on container
# startup as a background service.
COPY nginx_server/start-servers.sh /apps/computerstore/django_app/start-servers.sh
ENTRYPOINT ./start-servers.sh

