# syntax=docker/dockerfile:1.7
#
# Axelor Open Suite 9 - image de production
# Socle de référence (guide d'installation Axelor AOS 9 / AOP 8.2) :
#   Java 21 LTS - Tomcat 10.1.x (Jakarta EE 10) - PostgreSQL >= 16 (unaccent)
#   Reverse proxy Caddy (TLS) devant Tomcat
#
# Build :
#   DOCKER_BUILDKIT=1 docker build \
#     --build-arg AOS_VERSION=v9.2.0 \
#     --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
#     --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
#     --build-arg SOURCE_URL="https://github.com/<org>/<repo>" \
#     -t n2f:v1.0.0 .
#
# Modules privés (le token n'est jamais écrit dans une couche) :
#   --build-arg ADDITIONAL_MODULES="https://github.com/org/module-a.git|v1.0.0" \
#   --secret id=git_token,env=GIT_TOKEN
#
# Licence : Axelor est sous AGPLv3. Si vous modifiez le code et l'exposez sur
# un réseau, SOURCE_URL doit pointer vers les sources correspondantes.

############################################
# 1. SOURCES
############################################
FROM alpine:3.20 AS sources

# Toujours un tag ou un commit, jamais une branche mouvante
ARG AOS_VERSION=v9.2.0
ARG WEBAPP_VERSION=${AOS_VERSION}
# Liste séparée par des espaces. Format : "URL_GIT|REF" (REF = tag, branche ou commit)
ARG ADDITIONAL_MODULES=""

RUN apk add --no-cache git
WORKDIR /src

RUN --mount=type=secret,id=git_token,required=false \
    set -eu; \
    B64=""; \
    if [ -s /run/secrets/git_token ]; then \
      B64="$(printf 'x-access-token:%s' "$(cat /run/secrets/git_token)" | base64 | tr -d '\n')"; \
    fi; \
    clone() { \
      url="$1"; ref="$2"; dest="$3"; \
      if [ -n "$B64" ]; then \
        git -c "http.extraheader=Authorization: Basic ${B64}" clone --depth 1 ${ref:+--branch "$ref"} "$url" "$dest"; \
      else \
        git clone --depth 1 ${ref:+--branch "$ref"} "$url" "$dest"; \
      fi; \
    }; \
    clone https://github.com/axelor/open-suite-webapp.git "${WEBAPP_VERSION}" /src/webapp; \
    clone https://github.com/axelor/axelor-open-suite.git "${AOS_VERSION}" /src/webapp/modules/axelor-open-suite; \
    clone https://github.com/softstream2027/n2f-custo.git "main" /src/webapp/modules/n2f-custo; \
    for module in ${ADDITIONAL_MODULES}; do \
      url="${module%%|*}"; ref=""; \
      case "$module" in *"|"*) ref="${module#*|}" ;; esac; \
      name="$(basename "$url" .git)"; \
      clone "$url" "$ref" "/src/webapp/modules/${name}"; \
    done; \
    chmod +x /src/webapp/gradlew

############################################
# 2. BUILD (JDK 21 + cache Gradle)
############################################
FROM eclipse-temurin:21-jdk-jammy AS builder

ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Xmx2g -Dfile.encoding=UTF-8"

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=sources /src/webapp /app

RUN --mount=type=cache,target=/root/.gradle,sharing=locked \
    set -eux; \
    ./gradlew --no-daemon --parallel --build-cache \
      -xtest -xcheck -xspotlessApply build; \
    WAR_COUNT="$(ls build/libs/*.war | wc -l)"; \
    [ "${WAR_COUNT}" -eq 1 ] || { echo "1 WAR attendu, ${WAR_COUNT} trouve(s)"; ls -l build/libs; exit 1; }; \
    mkdir -p /opt/webapp/ROOT /opt/reports; \
    unzip -q build/libs/*.war -d /opt/webapp/ROOT; \
    if ls build/libs/*-reports.zip >/dev/null 2>&1; then \
      unzip -q build/libs/*-reports.zip -d /opt/reports; \
    fi

############################################
# 3. RUNTIME (JRE 21 + Tomcat 10.1, non-root)
############################################
FROM eclipse-temurin:21-jre-jammy

ARG UID=1000
ARG GID=1000
ARG TOMCAT_VERSION=10.1.55
ARG TZ=Europe/Paris
ARG AOS_VERSION=v9.2.0
ARG BUILD_DATE=""
ARG VCS_REF=""
ARG SOURCE_URL=""

LABEL org.opencontainers.image.title="Axelor Open Suite" \
      org.opencontainers.image.version="${AOS_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later"

ENV USER=axelor \
    HOME=/home/axelor \
    TZ=${TZ} \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENV CATALINA_HOME=${HOME}/tomcat \
    CATALINA_BASE=${HOME}/tomcat
ENV PATH=${CATALINA_HOME}/bin:${PATH}

ENV JAVA_OPTS="-Dfile.encoding=UTF-8 -Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Daxelor.ScriptCacheSize=500 -Daxelor.ScriptCacheExpireTime=10 -XX:+UseContainerSupport -XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError" \
    CATALINA_OPTS="-server"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl ca-certificates tzdata locales tini \
        fontconfig fonts-dejavu-core postgresql-client; \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
    locale-gen; \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    rm -rf /var/lib/apt/lists/*

# Utilisateur non-root et arborescence GED (cf. guide : attachments, exports, templates, reports)
RUN set -eux; \
    groupadd -g "${GID}" "${USER}"; \
    useradd -m -d "${HOME}" -u "${UID}" -g "${GID}" -s /bin/bash "${USER}"; \
    mkdir -p "${CATALINA_HOME}" /logs \
             /data/attachments /data/exports /data/templates /data/reports; \
    chown -R "${USER}:${USER}" "${HOME}" /data /logs

USER ${USER}
WORKDIR ${CATALINA_HOME}

# Tomcat 10.1 (jakarta.servlet), checksum SHA-512 verifie
RUN set -eux; \
    TOMCAT_MAJOR="${TOMCAT_VERSION%%.*}"; \
    BASE_URL="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin"; \
    curl -fsSL -o /tmp/tomcat.tar.gz "${BASE_URL}/apache-tomcat-${TOMCAT_VERSION}.tar.gz"; \
    EXPECTED="$(curl -fsSL "${BASE_URL}/apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512" | awk '{print $1}')"; \
    echo "${EXPECTED}  /tmp/tomcat.tar.gz" | sha512sum -c -; \
    tar xzf /tmp/tomcat.tar.gz --strip-components=1 -C "${CATALINA_HOME}"; \
    rm -f /tmp/tomcat.tar.gz; \
    rm -rf webapps/* temp/* work/* logs/*

# Configuration Tomcat derriere un reverse proxy TLS (Nginx/Caddy) :
#  - RemoteIpValve : le schema https n'est retenu que pour les requetes qui arrivent
#    avec X-Forwarded-Proto: https. Les appels internes en HTTP (ex. backend SaaS ->
#    http://app:8080) restent en HTTP et ne recoivent pas de cookie "Secure" inutilisable.
#  - port d'arret desactive, pas de version ni de stack trace dans les pages d'erreur
#  - endpoint /health (HealthCheckValve)
RUN set -eux; \
    sed -i '/<Valve className="org.apache.catalina.valves.AccessLogValve"/,/\/>/d' conf/server.xml; \
    sed -i '/<Connector port="8080"/,/\/>/c\    <Connector port="8080" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443" maxParameterCount="1000" />' conf/server.xml; \
    sed -i 's/<Server port="8005"/<Server port="-1"/' conf/server.xml; \
    sed -i '/<\/Host>/i <Valve className="org.apache.catalina.valves.HealthCheckValve" />' conf/server.xml; \
    sed -i '/<\/Host>/i <Valve className="org.apache.catalina.valves.ErrorReportValve" showReport="false" showServerInfo="false" />' conf/server.xml; \
    sed -i '/<\/Host>/i <Valve className="org.apache.catalina.valves.RemoteIpValve" />' conf/server.xml; \
    grep -q 'RemoteIpValve' conf/server.xml; \
    grep -q 'HealthCheckValve' conf/server.xml; \
    mkdir -p "${CATALINA_HOME}/webapps" "${CATALINA_HOME}/reports" "${CATALINA_HOME}/scripts"

COPY --from=builder --chown=${USER}:${USER} /opt/webapp/ ${CATALINA_HOME}/webapps/
COPY --from=builder --chown=${USER}:${USER} /opt/reports/ ${CATALINA_HOME}/reports/

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chmod=755 post-startup.d/ /usr/local/bin/post-startup.d/

# Premier demarrage long (migrations de schema) : 30 min, comme dans le guide Axelor
HEALTHCHECK --interval=30s --timeout=10s --start-period=1800s --retries=5 \
  CMD curl -fs http://localhost:8080/health || exit 1

EXPOSE 8080
STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["start"]