const accessDB = require('../../accessDB');

const buildGetFiles = (query) => (request, response) => {
  console.log('Calling CLI script to get data.');

  let queryStdout;

  try {
    ({ stdout: queryStdout } = accessDB.query(
      typeof query === 'function' ? query(request) : query,
    ));
  } catch (queryError) {
    console.log(`Query error: ${queryError}`);

    response.status(500).send();
  }

  console.log(
    `Query stdout (type=[${typeof queryStdout}]): ${JSON.stringify(
      queryStdout,
      null,
      2,
    )}`,
  );

  response.json(queryStdout);
};

module.exports = buildGetFiles;
