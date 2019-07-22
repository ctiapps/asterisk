FROM andrius/crystal-lang

RUN apt-get update \
 && apt-get install -yqq --no-install-suggests --no-install-recommends \
      asterisk \
      asterisk-config \
      asterisk-core-sounds-en-gsm \
      asterisk-moh-opsound-gsm \
 && rm -f rm /usr/lib/asterisk/modules/*pjsip*.so \
 && apt-get clean all \
 && rm -rf /tmp/* \
       /var/tmp/* \
       /var/lib/apt/lists/*

COPY ./spec/asterisk_configs/*.conf /etc/asterisk/

WORKDIR /src

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
