import passport from 'passport';
import { Strategy as LocalStrategy } from 'passport-local';

import { dbQuery, sub } from './lib/accessModule';
import { sanitize } from './lib/sanitize';
import { stdout } from './lib/shell';

passport.use(
  'login',
  new LocalStrategy((username, password, done) => {
    stdout(`Attempting passport local strategy "login" for user [${username}]`);

    let rows: [
      userUuid: string,
      userName: string,
      userPasswordHash: string,
      userSalt: string,
      userAlgorithm: string,
      userHashCount: string,
    ][];

    try {
      rows = dbQuery(
        `SELECT
          user_uuid,
          user_name,
          user_password_hash,
          user_salt,
          user_algorithm,
          user_hash_count
        FROM users
        WHERE user_algorithm != 'DELETED'
          AND user_name = '${username}'
        LIMIT 1;`,
      ).stdout;
    } catch (queryError) {
      return done(queryError);
    }

    if (!rows.length) {
      return done(null, false);
    }

    const {
      0: [userUuid, , userPasswordHash, userSalt, userAlgorithm, userHashCount],
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

  stdout(`Serialize user [${name}]`);

  return done(null, uuid);
});

passport.deserializeUser((id, done) => {
  const uuid = sanitize(id, 'string', { modifierType: 'sql' });

  stdout(`Deserialize user identified by ${uuid}`);

  let rows: [userName: string][];

  try {
    rows = dbQuery(
      `SELECT user_name
        FROM users
        WHERE user_algorithm != 'DELETED'
          AND user_uuid = '${uuid}';`,
    ).stdout;
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
