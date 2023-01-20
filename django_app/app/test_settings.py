from .settings import *

# Configured to use the local postgres instance run by the docker-compose config.
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'computerstore_test',
        'USER': 'computerstore_user',
        'PASSWORD': 'admin',
        'HOST': 'localhost',
        'PORT': 5432
    }
}