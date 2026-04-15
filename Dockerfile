# ----------------------------
# Build stage
# ----------------------------
FROM maven:3.9.6-eclipse-temurin-21 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml first to leverage Docker cache
COPY pom.xml ./

# Copy only the Maven wrapper if exists
COPY mvnw .
COPY .mvn .mvn

# Download dependencies (optional, may fail in restricted networks)
# If network unreliable, consider skipping this step
RUN mvn dependency:resolve -B || echo "Skipping offline resolve"

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# ----------------------------
# Runtime stage
# ----------------------------
FROM eclipse-temurin:21-jre-jammy

# Create app directory
WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy the built jar from build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose default Spring Boot port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
