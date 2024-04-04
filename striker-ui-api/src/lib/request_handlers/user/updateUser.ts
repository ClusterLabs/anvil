import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_PEACEFUL_STRING, REP_UUID } from '../../consts';

import { encrypt, query, write } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr, poutvar } from '../../shell';

export const updateUser: RequestHandler<
  UserParamsDictionary,
  undefined,
  UpdateUserRequestBody
> = async (request, response) => {
  const {
    body: { password: rPassword, userName: rUserName } = {},
    params: { userUuid },
    user: { name: sessionUserName, uuid: sessionUserUuid } = {},
  } = request;

  if (sessionUserName !== 'admin' && userUuid !== sessionUserUuid)
    return response.status(401).send();

  const password = sanitize(rPassword, 'string');
  const userName = sanitize(rUserName, 'string', { modifierType: 'sql' });

  poutvar({ password, userName }, `Update user ${userUuid} with params: `);

  try {
    if (password.length) {
      assert(
        REP_PEACEFUL_STRING.test(password),
        `Password must be a valid peaceful string; got: [${password}]`,
      );
    }

    if (userName.length) {
      assert(
        REP_PEACEFUL_STRING.test(userName),
        `User name must be a peaceful string; got: [${userName}]`,
      );
    }

    assert(
      REP_UUID.test(userUuid),
      `User UUID must be a valid UUIDv4; got: [${userUuid}]`,
    );

    const [[existingUserName]]: [[string]] = await query(
      `SELECT user_name FROM users WHERE user_uuid = '${userUuid}';`,
    );

    assert(existingUserName !== 'admin' || userName, 'Cannot ');
  } catch (error) {
    perr(`Assert failed when update user; CAUSE: ${error}`);

    return response.status(400).send();
  }

  let existingUser: [
    [
      user_name: string,
      user_password_hash: string,
      user_salt: string,
      user_algorithm: string,
      user_hash_count: string,
    ],
  ];

  try {
    existingUser = await query(
      `SELECT
          user_name,
          user_password_hash,
          user_salt,
          user_algorithm,
          user_hash_count
        FROM users
        WHERE user_uuid = '${userUuid}'
        ORDER BY modified_date DESC
        LIMIT 1;`,
    );
  } catch (error) {
    perr(`Failed to find existing user ${userUuid}; CAUSE: ${error}`);

    return response.status(500).send();
  }

  if (existingUser.length !== 1) {
    return response.status(404).send();
  }

  const [[xUserName, xPasswordHash, xSalt, xAlgorithm, xHashCount]] =
    existingUser;

  const assigns: string[] = [];

  if (password.length) {
    let passwordHash: string;

    try {
      ({ user_password_hash: passwordHash } = await encrypt({
        algorithm: xAlgorithm,
        hash_count: xHashCount,
        password,
        salt: xSalt,
      }));
    } catch (error) {
      perr(`Encrypt failed when update user; CAUSE ${error}`);

      return response.status(500).send();
    }

    if (passwordHash !== xPasswordHash) {
      assigns.push(`user_password_hash = '${passwordHash}'`);
    }
  }

  if (userName.length && xUserName !== 'admin' && userName !== xUserName) {
    assigns.push(`user_name = '${userName}'`);
  }

  if (assigns.length) {
    try {
      const wcode = await write(
        `UPDATE users SET ${assigns.join(
          ',',
        )} WHERE user_uuid = '${userUuid}';`,
      );

      assert(wcode === 0, `Update users failed with code: ${wcode}`);
    } catch (error) {
      perr(`Failed to record user changes to database; CAUSE: ${error}`);

      return response.status(500).send();
    }
  }

  return response.send();
};
