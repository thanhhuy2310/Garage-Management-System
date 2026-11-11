# Build React and Spring Boot into a single Render Web Service.
FROM node:22-bookworm-slim AS frontend-build
WORKDIR /build/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM maven:3.9-eclipse-temurin-21 AS backend-build
WORKDIR /build/backend
COPY backend/pom.xml ./
RUN mvn -B -ntp dependency:go-offline
COPY backend/src ./src
COPY --from=frontend-build /build/frontend/dist ./src/main/resources/static
RUN mvn -B -ntp -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=backend-build /build/backend/target/garage-management-backend-0.0.1-SNAPSHOT.jar /app/app.jar
ENV SERVER_ADDRESS=0.0.0.0
ENV SERVER_PORT=10000
ENV SPRING_PROFILES_ACTIVE=prod
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=60.0"
EXPOSE 10000
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
