FROM node:lts-alpine3.20

WORKDIR /app

COPY build/package*.json ./

RUN npm install

COPY build .

RUN npm run build

RUN npm install -g serve

EXPOSE 3000

CMD ["serve", "-s", "dist", "-l", "3000"]