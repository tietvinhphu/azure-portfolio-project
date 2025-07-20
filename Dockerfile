FROM node:18-slim
WORKDIR /usr/src/app
COPY app/package*.json ./
RUN npm install --production
COPY app/. .
EXPOSE 8080
CMD [ "npm", "start" ]