FROM node:16.6.1-alpine3.14

WORKDIR /app

COPY package.json /app

RUN npm install

COPY index.js /app
COPY ./lib /app/lib
COPY ./views /app/views
COPY ./public /app/public

ENTRYPOINT ["npm", "start"]