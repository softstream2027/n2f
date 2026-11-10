# syntax=docker/dockerfile:1.7

############################################
# 1. SOURCES (Clonage Axelor 9.2.0 + modules externes)
############################################
FROM alpine/git:latest AS sources

ARG AOS_VERSION=v9.2.0
ARG WEBAPP_VERSION=${AOS_VERSION}
# Format : "URL_DU_GIT" ou "URL_DU_GIT|BRANCHE" (séparés par espace)
# Exemple : "https://github.com/moi/module-a.git|main https://github.com/moi/module-b.git"
ARG ADDITIONAL_MODULES=""

WORKDIR /src

# Clonage des dépôts officiels d'Axelor
RUN set -eux; \
    git clone --depth 1 --branch "${WEBAPP_VERSION}" https://github.com/axelor/open-suite-webapp.git /src/webapp; \
    git clone --depth 1 --branch "${AOS_VERSION}" https://github.com/axelor/axelor-open-suite.git /src/webapp/modules/axelor-open-suite; \
    chmod +x /src/webapp/gradlew

# Clonage de vos modules spécifiques (boucle sur ADDITIONAL_MODULES)
RUN set -eux; \
    for module in $ADDITIONAL_MODULES; do \
      if echo "$module" | grep -q "|"; then \
        url=$(echo "$module" | cut -d'|' -f1); \
        branch=$(echo "$module" | cut -d'|' -f2); \
        name=$(basename "$url" .git); \
        git clone --depth 1 -b "$branch" "$url" "/src/webapp/modules/$name"; \
      else \
        name=$(basename "$module" .git); \
        git clone --depth 1 "$module" "/src/webapp/modules/$name"; \
      fi; \
    done

############################################
# 2. BUILD STAGE (Java 21 + Cache Gradle)
############################################
FROM eclipse-temurin:21-jdk-jammy AS builder

WORKDIR /app
COPY --from=sources /src/webapp /app

# Cache mount conservé pour éviter timeouts et consommation disque
RUN --mount=type=cache,target=/root/.gradle \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends unzip; \
    ./gradlew --no-daemon --parallel --build-cache -xtest -xcheck -xspotlessApply build; \
    mkdir -p /opt/webapp/ROOT; \
    unzip -q build/libs/*.war -d /opt/webapp/ROOT; \
    mkdir -p /opt/reports; \
    if ls build/libs/*-reports.zip >/dev/null 2>&1; then unzip -q build/libs/*-reports.zip -d /opt/reports; fi; \
    rm -rf /var/lib/apt/lists/*

############################################
# 3. RUNTIME STAGE (JRE 21 + Tomcat 10.1)
############################################
FROM eclipse-temurin:21-jre-jammy

ARG UID=1000
ARG GID=1000
ARG TOMCAT_VERSION=10.1.50
ARG BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

ENV USER=axelor
ENV HOME=/home/${USER}
ENV TZ=Europe/Paris
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ENV CATALINA_HOME=${HOME}/tomcat
ENV CATALINA_BASE=${HOME}/tomcat
ENV PATH=${CATALINA_HOME}/bin:${PATH}

# JVM optimisée conteneur (identique à votre ancienne version)
ENV JAVA_OPTS="-Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom -Daxelor.ScriptCacheSize=500 -Daxelor.ScriptCacheExpireTime=10 -XX:+UseContainerSupport -XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
ENV CATALINA_OPTS="-server"

# Outils de base
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl ca-certificates tzdata locales \
        fontconfig fonts-dejavu-core postgresql-client; \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
    locale-gen; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    rm -rf /var/lib/apt/lists/*

# Utilisateur et dossiers
RUN set -eux; \
    groupadd -g ${GID} ${USER}; \
    useradd -m -d ${HOME} -u ${UID} -g ${GID} -s /bin/bash ${USER}; \
    mkdir -p ${CATALINA_HOME} /data /logs; \
    chown -R ${USER}:${USER} ${HOME} /data /logs

USER ${USER}
WORKDIR ${CATALINA_HOME}

# Installation de Tomcat 10.1 (jakarta.servlet, requis par Axelor 9)
RUN set -eux; \
    TOMCAT_MAJOR="${TOMCAT_VERSION%%.*}"; \
    curl -fsSL "https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
      | tar xz --strip-components=1 -C ${CATALINA_HOME}; \
    rm -rf webapps/* temp/* work/* logs/*

# Optimisation Tomcat (HealthCheck, logs) - inchangé
RUN set -eux; \
    sed -i '/AccessLogValve/d' conf/server.xml; \
    sed -i '/<\/Host>/i\
<Valve className="org.apache.catalina.valves.HealthCheckValve" \/>' conf/server.xml; \
    mkdir -p ${CATALINA_HOME}/webapps ${CATALINA_HOME}/reports ${CATALINA_HOME}/scripts

# Copie de l'application compilée
COPY --from=builder --chown=${USER}:${USER} /opt/webapp/ ${CATALINA_HOME}/webapps/
COPY --from=builder --chown=${USER}:${USER} /opt/reports/ ${CATALINA_HOME}/reports/

# Entrypoint et Healthcheck (conservés tels quels)
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chmod=755 post-startup.d/ /usr/local/bin/post-startup.d/

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fs http://localhost:8080/ || exit 1

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["start"]