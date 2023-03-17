import { RequestHandler } from 'express';

import { dbQuery, getLocalHostName } from '../../accessModule';
import {
  getHostNameDomain,
  getHostNamePrefix,
  getShortHostName,
} from '../../disassembleHostName';
import { stderr } from '../../shell';

export const getManifestTemplate: RequestHandler = (request, response) => {
  let localHostName = '';

  try {
    localHostName = getLocalHostName();
  } catch (subError) {
    stderr(String(subError));

    response.status(500).send();

    return;
  }

  const localDomain = getHostNameDomain(localHostName);
  const localShort = getShortHostName(localHostName);
  const localPrefix = getHostNamePrefix(localShort);

  let rawQueryResult: Array<
    [fenceUUID: string, fenceName: string, upsUUID: string, upsName: string]
  >;

  try {
    ({ stdout: rawQueryResult } = dbQuery(
      `SELECT
          fence_uuid,
          fence_name,
          ups_uuid,
          ups_name
        FROM (
          SELECT
            ROW_NUMBER() OVER (ORDER BY fence_name),
            fence_uuid,
            fence_name
          FROM fences
          ORDER BY fence_name
        ) AS a
        FULL JOIN (
          SELECT
            ROW_NUMBER() OVER (ORDER BY ups_name),
            ups_uuid,
            ups_name
          FROM upses
          ORDER BY ups_name
        ) AS b ON a.row_number = b.row_number;`,
    ));
  } catch (queryError) {
    stderr(`Failed to execute query; CAUSE: ${queryError}`);

    response.status(500).send();

    return;
  }

  const queryResult = rawQueryResult.reduce<{
    fences: {
      [fenceUUID: string]: {
        fenceName: string;
        fenceUUID: string;
      };
    };
    upses: {
      [upsUUID: string]: {
        upsName: string;
        upsUUID: string;
      };
    };
  }>(
    (previous, [fenceUUID, fenceName, upsUUID, upsName]) => {
      const { fences, upses } = previous;

      if (fenceUUID) {
        fences[fenceUUID] = {
          fenceName,
          fenceUUID,
        };
      }

      if (upsUUID) {
        upses[upsUUID] = {
          upsName,
          upsUUID,
        };
      }

      return previous;
    },
    { fences: {}, upses: {} },
  );

  response.status(200).send({
    localHostName,
    localShort,
    localPrefix,
    localDomain,
    ...queryResult,
  });
};
