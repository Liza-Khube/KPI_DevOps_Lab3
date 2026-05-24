FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

ENV NODE_ENV=production
ENV CONFIG_PATH=/etc/mywebapp/config.json

USER node

EXPOSE 8080

ENTRYPOINT ["docker-entrypoint.sh"]