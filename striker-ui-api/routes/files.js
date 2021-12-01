const express = require('express');
const { spawnSync } = require('child_process');

const router = express.Router();

router.get('/', (request, response) => {
  console.log('Calling CLI script to get data.');

  const childProcess = spawnSync(
    'striker-access-database',
    ['--query', 'SELECT * FROM files;'],
    {
      timeout: 10000,
      encoding: 'utf-8',
    },
  );

  if (childProcess.error)
  {
      response.status(500);
  }

  console.log('error:', childProcess.error);
  console.log('stdout:', childProcess.stdout);
  console.log('stderr:', childProcess.stderr);

  response.status(200).send(childProcess.stdout);
});

module.exports = router;
