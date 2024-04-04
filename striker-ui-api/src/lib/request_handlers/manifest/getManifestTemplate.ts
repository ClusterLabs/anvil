import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { getLocalHostName, query } from '../../accessModule';
import {
  getHostNameDomain,
  getHostNamePrefix,
  getShortHostName,
} from '../../disassembleHostName';
import { perr } from '../../shell';

export const getManifestTemplate: RequestHandler = async (
  request,
  response,
) => {
  let localHostName: string;

  try {
    localHostName = getLocalHostName();
  } catch (subError) {
    perr(String(subError));

    return response.status(500).send();
  }

  const localShortHostName = getShortHostName(localHostName);

  const domain = getHostNameDomain(localHostName);
  const prefix = getHostNamePrefix(localShortHostName);

  let rawQueryResult: Array<
    [
      fenceUUID: string,
      fenceName: string,
      upsUUID: string,
      upsName: string,
      manifestUuid: string,
      lastSequence: string,
    ]
  >;

  try {
    rawQueryResult = await query(
      `SELECT
          a.fence_uuid,
          a.fence_name,
          b.ups_uuid,
          b.ups_name,
          c.last_sequence
        FROM (
          SELECT
            ROW_NUMBER() OVER (ORDER BY fence_name),
            fence_uuid,
            fence_name
          FROM fences
          WHERE fence_arguments != '${DELETED}'
          ORDER BY fence_name
        ) AS a
        FULL JOIN (
          SELECT
            ROW_NUMBER() OVER (ORDER BY ups_name),
            ups_uuid,
            ups_name
          FROM upses
          WHERE ups_ip_address != '${DELETED}'
          ORDER BY ups_name
        ) AS b ON a.row_number = b.row_number
        FULL JOIN (
          SELECT
            ROW_NUMBER() OVER (ORDER BY manifest_name DESC),
            CAST(
              SUBSTRING(manifest_name, '([\\d]*)$') AS INTEGER
            ) AS last_sequence
          FROM manifests
          WHERE manifest_note != '${DELETED}'
          ORDER BY manifest_name DESC
          LIMIT 1
        ) AS c ON a.row_number = c.row_number;`,
    );
  } catch (queryError) {
    perr(`Failed to execute query; CAUSE: ${queryError}`);

    return response.status(500).send();
  }

  const queryResult = rawQueryResult.reduce<
    Pick<ManifestTemplate, 'fences' | 'sequence' | 'upses'>
  >(
    (previous, [fenceUUID, fenceName, upsUUID, upsName, lastSequence]) => {
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

      if (lastSequence) {
        previous.sequence = Number(lastSequence) + 1;
      }

      return previous;
    },
    { fences: {}, sequence: 1, upses: {} },
  );

  const result: ManifestTemplate = {
    domain,
    prefix,
    ...queryResult,
  };

  response.status(200).send(result);
};
