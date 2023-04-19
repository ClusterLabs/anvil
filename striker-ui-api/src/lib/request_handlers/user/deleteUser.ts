import assert from 'assert';
import { RequestHandler } from 'express';

import { DELETED, REP_UUID } from '../../consts';

import { awrite } from '../../accessModule';
import join from '../../join';
import { sanitize } from '../../sanitize';
import { stderr, stdoutVar } from '../../shell';

export const deleteUser: RequestHandler<
  DeleteUserParamsDictionary,
  undefined,
  DeleteUserRequestBody
> = (request, response) => {
  const {
    body: { uuids: rawUserUuidList } = {},
    params: { userUuid },
  } = request;

  const userUuidList = sanitize(rawUserUuidList, 'string[]');

  const ulist = userUuidList.length > 0 ? userUuidList : [userUuid];

  stdoutVar({ ulist });

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
    stderr(`Failed to assert value during delete user; CAUSE: ${assertError}`);

    return response.status(400).send();
  }

  try {
    awrite(
      `UPDATE users
        SET user_algorithm = '${DELETED}'
        WHERE user_uuid IN (${join(ulist)});`,
      {
        onClose: ({ ecode, wcode }) => {
          if (ecode !== 0 || wcode !== 0) {
            stderr(
              `SQL script failed in delete user(s); ecode=${ecode}, wcode=${wcode}`,
            );
          }
        },
        onError: (error) => {
          stderr(`Delete user subprocess error; CAUSE: ${error}`);
        },
      },
    );
  } catch (error) {
    stderr(`Failed to delete user(s); CAUSE: ${error}`);

    return response.status(500).send();
  }

  response.status(204).send();
};
