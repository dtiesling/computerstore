import multiprocessing
import os

bind = ':8000'
workers = multiprocessing.cpu_count() * 2
threads = 4
timeout = 0
limit_request_field_size = 0
limit_request_line = 0
if os.environ.get('DEBUG') == 'true':
    log_level = 'debug'
