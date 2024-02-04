import assert from 'assert';

import { REP_UUID } from '../../consts';

import { sanitize } from '../../sanitize';

export const getAlertOverrideRequestBody = (
  body: Partial<AlertOverrideRequestBody>,
  uuid?: string,
): AlertOverrideRequestBody => {
  const {
    hostUuid: rHostUuid,
    level: rLevel,
    mailRecipientUuid: rMailRecipientUuid,
  } = body;

  const hostUuid = sanitize(rHostUuid, 'string');
  const level = sanitize(rLevel, 'number');
  const mailRecipientUuid = sanitize(rMailRecipientUuid, 'string');

  if (uuid) {
    assert(REP_UUID.test(uuid), `Expected valid UUIDv4; got [${uuid}]`);
  }

  assert(
    REP_UUID.test(hostUuid),
    `Expected valid host UUIDv4; got [${hostUuid}]`,
  );

  assert(
    Number.isSafeInteger(level),
    `Expected level to be an integer; got [${level}]`,
  );

  assert(
    REP_UUID.test(mailRecipientUuid),
    `Expected valid mail recipient UUIDv4; got [${mailRecipientUuid}]`,
  );

  return {
    hostUuid,
    level,
    mailRecipientUuid,
  };
};
