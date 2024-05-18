FROM ubuntu:latest as userCreator

RUN groupadd -r npm && useradd -r -g npm npm

FROM node:16.14.0-alpine

WORKDIR /app

COPY --from=userCreator /etc/passwd /etc/passwd

COPY --from=userCreator /etc/group /etc/group

COPY ./package.json .

COPY ./package-lock.json .

RUN mkdir -p /app/log /home/npm && \ 
    chown -R npm:npm /app /home/npm && \
    touch /app/log/access.log && \
    chmod o+rwx /app/log/access.log
    
USER npm 

RUN npm install && npm cache clean --force

COPY . .

RUN npm run build

EXPOSE 4000

CMD [ "npm", "start" ]