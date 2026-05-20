const app = require('./app');
const config = require('./config');

const host = config.server.host;
const port = config.server.port;

if (process.env.LISTEN_FDS && parseInt(process.env.LISTEN_FDS) >= 1) {
  app.listen({ fd: 3 }, () => {
    console.log('mywebapp listening on systemd socket');
  });
} else {
  app.listen(port, host, () => {
    console.log(`mywebapp listening on ${host}: ${port}`);
  });
}
