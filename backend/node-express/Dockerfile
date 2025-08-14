FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Expose port 3001 to match docker-compose mapping
EXPOSE 3001

# Start the application
CMD ["npm", "start"]