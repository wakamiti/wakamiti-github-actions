FROM wiremock/wiremock

RUN mkdir -p /certs
RUN if [ ! -f /certs/keystore.jks ]; then \
      keytool -genkeypair \
        -alias mockserver \
        -keyalg RSA \
        -keysize 2048 \
        -validity 365 \
        -keystore /certs/mockserver.jks \
        -storepass password \
        -keypass password \
        -dname "CN=WireMock, OU=Dev, O=MockServer, C=ES" \
        -ext "SAN=DNS:mockserver,DNS:localhost,IP:127.0.0.1"  \
    && keytool -exportcert \
         -alias mockserver \
         -keystore /certs/mockserver.jks \
         -storepass password \
         -rfc \
         -file /certs/mockserver.crt ; \
    fi
RUN chmod 644 /certs/*




