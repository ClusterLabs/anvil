const app = require('./app');

const SERVER_PORT = require('./lib/consts/SERVER_PORT');

app.listen(SERVER_PORT, () => {
  console.log(`Listening on localhost:${SERVER_PORT}.`);
});
