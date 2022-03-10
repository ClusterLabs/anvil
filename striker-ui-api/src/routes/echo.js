const express = require('express');

const router = express.Router();

router
  .get('/', (request, response) => {
    response.status(200).send({ message: 'Empty echo.' });
  })
  .post('/', (request, response) => {
    console.log('echo:post', JSON.stringify(request.body, undefined, 2));

    const message = request.body.message ?? 'No message.';

    response.status(200).send({ message });
  });

module.exports = router;
