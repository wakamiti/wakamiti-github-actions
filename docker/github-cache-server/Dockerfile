# Build stage
FROM node:16 AS build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install

# Production stage
FROM node:16
WORKDIR /usr/src/app
RUN mkdir -p /usr/src/app/.caches
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY package*.json ./
COPY src src
ARG AUTH_KEY
ENV AUTH_KEY=${AUTH_KEY}
EXPOSE 8080
CMD [ "node", "src/index.js" ]
