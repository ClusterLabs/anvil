import assert from 'assert';
import { RequestHandler } from 'express';

import { DELETED, REP_PEACEFUL_STRING, REP_UUID } from '../../consts';

import { insertOrUpdateUser, query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { openssl, perr, poutvar } from '../../shell';

export const createUser: RequestHandler<
  unknown,
  CreateUserResponseBody,
  CreateUserRequestBody
> = async (request, response) => {
  const {
    body: { password: rPassword, userName: rUserName } = {},
    user: { name: sessionUserName } = {},
  } = request;

  if (sessionUserName !== 'admin') return response.status(401).send();

  const password = sanitize(rPassword, 'string', {
    fallback: openssl('rand', '-base64', '12').trim().replaceAll('/', '!'),
  });
  const userName = sanitize(rUserName, 'string', { modifierType: 'sql' });

  poutvar({ password, userName }, 'Create user with params: ');

  try {
    assert(
      REP_PEACEFUL_STRING.test(password),
      `Password must be a peaceful string; got: [${password}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(userName),
      `User name must be a peaceful string; got: [${userName}]`,
    );

    const [[userCount]]: [[number]] = await query(
      `SELECT COUNT(user_uuid)
        FROM users
        WHERE user_algorithm != '${DELETED}' AND user_name = '${userName}';`,
    );

    assert(userCount === 0, `User name [${userName}] already used`);
  } catch (error) {
    perr(`Failed to assert value when creating user; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    const result = await insertOrUpdateUser({
      file: __filename,
      user_name: userName,
      user_password_hash: password,
    });

    assert(
      REP_UUID.test(result),
      `Insert or update failed with result [${result}]`,
    );
  } catch (error) {
    perr(`Failed to record user to database; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(201).send({ password });
};
