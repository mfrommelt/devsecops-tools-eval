# Use official MuleSoft runtime image
FROM mulesoft/mule4-runtime:4.4.0-java8

# Copy your application
COPY target/*.jar /opt/mule/apps/

# Copy configuration files
COPY src/main/resources/*.properties /opt/mule/conf/
COPY src/main/resources/*.xml /opt/mule/conf/

# Expose ports
EXPOSE 8081 8082

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8081/health || exit 1