{% set dewey_uid = salt['pillar.get']('uids:dewey:uid', 'None') %}
{% set dewey_gid = salt['pillar.get']('uids:dewey:gid', 'None') %}
{% set dewey_version = salt['pillar.get']('version:dewey', 'None') %}
{% set postgres_password = salt['pillar.get']('secrets:dewey:postgres', 'Aiy5vah0cheep') %}
{% set postgres_major = salt['pillar.get']('version:postgresql_major', '9.4') %}

include:
  - common.repos
  - nginx
  - postgres
  - redis.master

dewey:
  group:
    - present
    - gid: {{ dewey_gid }}
  user:
    - present
    - uid: {{ dewey_uid }}
    - home: /opt/dewey
    - shell: /bin/bash
    - gid_from_name: true
    - require:
      - group: dewey
  pkg.installed:
    - version: {{ dewey_version }}
    - require:
      - user: dewey
  service.running:
    - enable: true
    - require:
      - pkg: dewey
      - file: /etc/default/dewey
    - watch:
      - file: /etc/default/dewey

dewey-worker:
  service.running:
    - enable: true
    - require:
      - pkg: dewey
      - file: /etc/default/dewey

dewey-scheduler:
  service.running:
    - enable: true
    - require:
      - service: dewey-worker

/etc/default/dewey:
  file.managed:
    - source: salt://dewey/etc/default/dewey
    - template: jinja
    - user: dewey
    - group: dewey
    - mode: 0640

/etc/nginx/sites-available/dewey.conf:
  file.managed:
    - source: salt://dewey/etc/nginx/sites-available/dewey.conf
    - template: jinja

/etc/nginx/sites-enabled/dewey.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/dewey.conf
    - require:
      - file: /etc/nginx/sites-available/dewey.conf

dewey_postgres_user:
  postgres_user.present:
    - name: dewey
    - password: {{ postgres_password }}
    - encrypted: true
    - require:
      - pkg: postgresql

dewey_postgres_database:
  postgres_database.present:
    - name: dewey
    - owner: dewey
    - encoding: UTF8
    - lc_collate: en_US.UTF-8
    - lc_ctype: en_US.UTF-8
    - require:
      - postgres_user: dewey_postgres_user

extend:
  apt-repo-plos:
    pkgrepo.managed:
      - require_in:
        - pkg: dewey
  /etc/redis/common.conf:
    file.managed:
      - context:
        addy_bind: ""
  /etc/postgresql/{{ postgres_major }}/main/postgresql.conf:
    file.managed:
      - context:
          listen: 127.0.0.1
  nginx:
    service.running:
      - watch:
        - file: /etc/nginx/sites-available/dewey.conf