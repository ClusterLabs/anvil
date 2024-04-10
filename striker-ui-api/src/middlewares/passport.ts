import passport from 'passport';
import { Strategy as LocalStrategy } from 'passport-local';

import { DELETED } from '../lib/consts';

import { encrypt, query } from '../lib/accessModule';
import { sanitize } from '../lib/sanitize';
import { pout } from '../lib/shell';

passport.use(
  'login',
  new LocalStrategy(async (username, password, done) => {
    pout(`Attempting passport local strategy "login" for user [${username}]`);

    let rows: [
      userUuid: string,
      userName: string,
      userPasswordHash: string,
      userSalt: string,
      userAlgorithm: string,
      userHashCount: string,
    ][];

    try {
      rows = await query(
        `SELECT
          user_uuid,
          user_name,
          user_password_hash,
          user_salt,
          user_algorithm,
          user_hash_count
        FROM users
        WHERE user_algorithm != '${DELETED}'
          AND user_name = '${username}'
        ORDER BY modified_date DESC
        LIMIT 1;`,
      );
    } catch (queryError) {
      return done(queryError);
    }

    if (!rows.length) {
      return done(null, false);
    }

    const {
      0: [userUuid, , userPasswordHash, userSalt, userAlgorithm, userHashCount],
    } = rows;

    let encryptResult: Encrypted;

    try {
      encryptResult = await encrypt({
        algorithm: userAlgorithm,
        hash_count: userHashCount,
        password,
        salt: userSalt,
      });
    } catch (subError) {
      return done(subError);
    }

    const { user_password_hash: inputPasswordHash } = encryptResult;

    if (inputPasswordHash !== userPasswordHash) {
      return done(null, false);
    }

    const user: Express.User = {
      name: username,
      uuid: userUuid,
    };

    return done(null, user);
  }),
);

passport.serializeUser((user, done) => {
  const { name, uuid } = user;

  pout(`Serialize user [${name}]`);

  return done(null, uuid);
});

passport.deserializeUser(async (id, done) => {
  const uuid = sanitize(id, 'string', { modifierType: 'sql' });

  pout(`Deserialize user identified by ${uuid}`);

  let rows: [userName: string][];

  try {
    rows = await query(
      `SELECT user_name
        FROM users
        WHERE user_algorithm != '${DELETED}'
          AND user_uuid = '${uuid}';`,
    );
  } catch (error) {
    return done(error);
  }

  if (!rows.length) {
    return done(null, false);
  }

  const {
    0: [userName],
  } = rows;

  const user: Express.User = { name: userName, uuid };

  return done(null, user);
});

export default passport;
