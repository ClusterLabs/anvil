import assert from 'assert';

import { REP_UUID } from '../../consts';

import { sanitize } from '../../sanitize';

export const getMailRecipientRequestBody = (
  body: Partial<MailRecipientRequestBody>,
  uuid?: string,
): MailRecipientRequestBody => {
  const {
    email: rEmail,
    language: rLanguage,
    level: rLevel,
    name: rName,
  } = body;

  const email = sanitize(rEmail, 'string');
  const language = sanitize(rLanguage, 'string', { fallback: 'en_CA' });
  const level = sanitize(rLevel, 'number');
  const name = sanitize(rName, 'string');

  if (uuid) {
    assert(REP_UUID.test(uuid), `Expected valid UUIDv4; got [${uuid}]`);
  }

  assert.ok(email.length, `Expected email; got [${email}]`);

  if (language) {
    assert.ok(
      language.length,
      `Expected valid language code; got [${language}]`,
    );
  }

  assert(
    Number.isSafeInteger(level),
    `Expected level to be an integer; got [${level}]`,
  );

  assert.ok(name.length, `Expected name; got [${name}]`);

  return {
    email,
    language,
    level,
    name,
  };
};
