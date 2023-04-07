import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_PEACEFUL_STRING } from '../../consts/REG_EXP_PATTERNS';

import { dbQuery, sub } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { stderr } from '../../shell';

export const login: RequestHandler<unknown, unknown, AuthLoginRequestBody> = (
  request,
  response,
) => {
  const {
    body: { password: rawPassword, username: rawUsername },
  } = request;

  const password = sanitize(rawPassword, 'string');
  const username = sanitize(rawUsername, 'string', { modifierType: 'sql' });

  try {
    assert(
      REP_PEACEFUL_STRING.test(username),
      `Username must be a peaceful string; got [${username}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(password),
      `Password must be a peaceful string; got [${password}]`,
    );
  } catch (assertError) {
    stderr(
      `Assertion failed when attempting to authenticate; CAUSE: ${assertError}`,
    );

    response.status(400).send();

    return;
  }

  let rows: [
    userUuid: string,
    userPasswordHash: string,
    userSalt: string,
    userAlgorithm: string,
    userHashCount: string,
  ][];

  try {
    rows = dbQuery(`
      SELECT
        user_uuid,
        user_password_hash,
        user_salt,
        user_algorithm,
        user_hash_count
      FROM users
      WHERE user_algorithm != 'DELETED'
        AND user_name = '${username}'`).stdout;
  } catch (queryError) {
    stderr(`Failed to get user ${username}; CAUSE: ${queryError}`);
    response.status(500).send();
    return;
  }

  if (rows.length === 0) {
    stderr(`No entry for user ${username} found`);
    response.status(404).send();
    return;
  }

  const {
    0: { 1: userPasswordHash, 2: userSalt, 3: userAlgorithm, 4: userHashCount },
  } = rows;

  let encryptResult: {
    user_password_hash: string;
    user_salt: string;
    user_hash_count: number;
    user_algorithm: string;
  };

  try {
    encryptResult = sub('encrypt_password', {
      subModuleName: 'Account',
      subParams: {
        algorithm: userAlgorithm,
        hash_count: userHashCount,
        password,
        salt: userSalt,
      },
    }).stdout;
  } catch (subError) {
    stderr(`Failed to login with username ${username}; CAUSE: ${subError}`);
    response.status(500).send();
    return;
  }

  const { user_password_hash: inputPasswordHash } = encryptResult;

  if (inputPasswordHash !== userPasswordHash) {
    stderr(`Input and recorded password mismatched.`);
    response.status(400).send();
    return;
  }

  response.status(200).send();
};
