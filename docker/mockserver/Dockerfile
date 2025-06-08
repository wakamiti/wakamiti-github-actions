FROM wiremock/wiremock

# Generate certificates in a single layer to reduce image size
RUN mkdir -p /certs && \
    keytool -genkeypair \
      -alias mockserver \
      -keyalg RSA \
      -keysize 2048 \
      -validity 365 \
      -keystore /certs/mockserver.jks \
      -storepass password \
      -keypass password \
      -dname "CN=WireMock, OU=Dev, O=MockServer, C=ES" \
      -ext "SAN=DNS:mockserver,DNS:localhost,IP:127.0.0.1" && \
    keytool -exportcert \
      -alias mockserver \
      -keystore /certs/mockserver.jks \
      -storepass password \
      -rfc \
      -file /certs/mockserver.crt && \
    chmod 644 /certs/*

# Add healthcheck to ensure service is ready
HEALTHCHECK --interval=10s --timeout=20s --retries=20 \
  CMD curl -k https://localhost:8443/__admin/mappings || exit 1
