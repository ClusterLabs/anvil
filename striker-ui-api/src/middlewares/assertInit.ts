import { Handler } from 'express';

import { LOCAL } from '../lib/consts';

import { query } from '../lib/accessModule';
import { toHostUUID } from '../lib/convertHostUUID';
import { perr, poutvar } from '../lib/shell';

/**
 * expressjs middleware for checking whether the target host is configured. It
 * calls `succeed()` when the target host is configured, and calls `fail()`
 * otherwise.
 *
 * @param fail - callback when check fails
 * @param hostUuid - UUID of the host to check
 * @param invert - when `true`, succeeds when host is **not** configured
 * @param succeed - callback when check passes
 * @returns result of callback on success or failure
 */
export const assertInit =
  ({
    fail = (rq, rs) => rs.status(401).send(),
    hostUuid: rHostUuid = LOCAL,
    invert,
    succeed = (rq, rs, nx) => nx(),
  }: {
    fail?: (...args: Parameters<Handler>) => void;
    hostUuid?: string;
    invert?: boolean;
    succeed?: (...args: Parameters<Handler>) => void;
  } = {}): Handler =>
  async (...args) => {
    const { 1: response } = args;
    const hostUuid = toHostUUID(rHostUuid);

    let rows: [[string]];

    try {
      rows = await query(
        `SELECT variable_value
          FROM variables
          WHERE variable_name = 'system::configured'
            AND variable_source_table = 'hosts'
            AND variable_source_uuid = '${hostUuid}'
          LIMIT 1;`,
      );
    } catch (error) {
      perr(`Failed to get system configured flag; CAUSE: ${error}`);

      return response.status(500).send();
    }

    poutvar(rows, `Configured variable of host ${hostUuid}: `);

    let condition = rows.length === 1 && rows[0][0] === '1';

    if (invert) condition = !condition;

    if (condition) {
      perr(`Assert init failed; invert=${invert}`);

      return fail(...args);
    }

    return succeed(...args);
  };
