import assert from 'assert';
import { RequestHandler } from 'express';

import { DELETED, REP_UUID } from '../../consts';

import { write } from '../../accessModule';
import join from '../../join';
import { sanitize } from '../../sanitize';
import { perr, poutvar } from '../../shell';

export const deleteUser: RequestHandler<
  UserParamsDictionary,
  undefined,
  DeleteUserRequestBody
> = async (request, response) => {
  const {
    body: { uuids: rawUserUuidList } = {},
    params: { userUuid },
    user: { name: sessionUserName } = {},
  } = request;

  if (sessionUserName !== 'admin') return response.status(401).send();

  const userUuidList = sanitize(rawUserUuidList, 'string[]');

  const ulist = userUuidList.length > 0 ? userUuidList : [userUuid];

  poutvar({ ulist });

  try {
    let failedIndex = 0;

    assert(
      ulist.every((uuid, index) => {
        failedIndex = index;

        return REP_UUID.test(uuid);
      }),
      `All UUIDs must be valid UUIDv4; failed at ${failedIndex}, got [${ulist[failedIndex]}]`,
    );
  } catch (assertError) {
    perr(`Failed to assert value during delete user; CAUSE: ${assertError}`);

    return response.status(400).send();
  }

  try {
    const wcode = await write(
      `UPDATE users
        SET user_algorithm = '${DELETED}'
        WHERE user_uuid IN (${join(ulist, {
          elementWrapper: "'",
          separator: ',',
        })});`,
    );

    assert(wcode === 0, `Write exited with code ${wcode}`);
  } catch (error) {
    perr(`Failed to delete user(s); CAUSE: ${error}`);

    return response.status(500).send();
  }

  response.status(204).send();
};
