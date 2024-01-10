import assert from 'assert';

import { sanitize } from '../../sanitize';

export const getMailServerRequestBody = (
  body: Partial<MailServerRequestBody>,
): MailServerRequestBody => {
  const {
    address: rAddress,
    authentication: rAuthentication,
    heloDomain: rHeloDomain,
    password: rPassword,
    port: rPort,
    security: rSecurity,
    username: rUsername,
  } = body;

  const address = sanitize(rAddress, 'string');
  const authentication = sanitize(rAuthentication, 'string', {
    fallback: 'none',
  });
  const heloDomain = sanitize(rHeloDomain, 'string');
  const password = sanitize(rPassword, 'string');
  const port = sanitize(rPort, 'number', { fallback: 587 });
  const security = sanitize(rSecurity, 'string', { fallback: 'none' });
  const username = sanitize(rUsername, 'string');

  assert.ok(address.length, `Expected address; got [${address}]`);

  assert(
    ['none', 'plain-text', 'encrypted'].includes(authentication),
    `Expected authentication to be 'none', 'plain-text', or 'encrypted'; got [${authentication}]`,
  );

  assert.ok(heloDomain.length, `Expected HELO domain; got [${heloDomain}]`);

  assert(
    Number.isSafeInteger(port),
    `Expected port to be an integer; got [${port}]`,
  );

  assert(
    ['none', 'starttls', 'tls-ssl'].includes(security),
    `Expected security to be 'none', 'starttls', or 'tls-ssl'; got [${security}]`,
  );

  return {
    address,
    authentication,
    heloDomain,
    password,
    port,
    security,
    username,
  };
};
