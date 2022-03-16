import app from './app';

import SERVER_PORT from './lib/consts/SERVER_PORT';

app.listen(SERVER_PORT, () => {
  console.log(`Listening on localhost:${SERVER_PORT}.`);
});
