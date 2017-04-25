{%- from "nginx/map.jinja" import server with context %}
{%- if server.enabled %}

nginx_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

{%- if server.get('extras', False) %}
nginx_extra_packages:
  pkg.installed:
  - name: nginx-extras
{%- endif %}

/etc/nginx/sites-enabled/default:
  file.absent:
  - require:
    - pkg: nginx_packages

/etc/nginx/sites-available/default:
  file.absent:
  - require:
    - pkg: nginx_packages


{%- if server.undercloud | default(false) %}

/etc/nginx/nginx.conf:
  file.managed:
  - source: salt://nginx/files/nginx.conf.j2
  - template: jinja
  - require:
    - pkg: nginx_packages
  - watch_in:
    - service: nginx_service

httpboot_folder:
  cmd.run
  - name test -d {{ server.http_boot_folder }} || mkdir -p {{ server.http_boot_folder }}
  - require
    - pkg: nginx_packages
    
{%- else %}
include:
  - nginx.server.users
  - nginx.server.sites

/etc/nginx/nginx.conf:
  file.managed:
  - source: salt://nginx/files/nginx.conf
  - template: jinja
  - require:
    - pkg: nginx_packages
  - watch_in:
    - service: nginx_service
{%- endif %}

nginx_service:
  service.running:
  - name: {{ server.service }}
  - require:
    - pkg: nginx_packages

nginx_generate_dhparams:
  cmd.run:
  - name: openssl dhparam -out /etc/ssl/dhparams.pem 2048
  - creates: /etc/ssl/dhparams.pem
  - require:
    - pkg: nginx_packages
  - watch_in:
    - service: nginx_service

{%- endif %}
