import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_PEACEFUL_STRING } from '../../consts';

import { getFenceSpec, timestamp, write } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { stderr, stdoutVar, uuid } from '../../shell';

const MAP_TO_VAR_TYPE: Record<
  AnvilDataFenceParameterType,
  'boolean' | 'number' | 'string'
> = {
  boolean: 'boolean',
  integer: 'number',
  second: 'number',
  select: 'string',
  string: 'string',
};

export const createFence: RequestHandler<
  { uuid?: string },
  undefined,
  {
    agent: string;
    name: string;
    parameters: { [parameterId: string]: boolean | number | string };
  }
> = async (request, response) => {
  const {
    body: { agent: rAgent, name: rName, parameters: rParameters },
    params: { uuid: rUuid },
  } = request;

  let fenceSpec: AnvilDataFenceHash;

  try {
    fenceSpec = await getFenceSpec();
  } catch (error) {
    stderr(`Failed to get fence devices specification; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const agent = sanitize(rAgent, 'string');
  const name = sanitize(rName, 'string');
  const fenceUuid = sanitize(rUuid, 'string', { fallback: uuid() });

  const { [agent]: agentSpec } = fenceSpec;

  try {
    assert.ok(agentSpec, `Agent is unknown to spec; got [${agent}]`);

    assert(
      REP_PEACEFUL_STRING.test(name),
      `Name must be a peaceful string; got [${name}]`,
    );

    const rParamsType = typeof rParameters;

    assert(
      rParamsType === 'object',
      `Parameters must be an object; got type [${rParamsType}]`,
    );
  } catch (error) {
    assert(
      `Failed to assert value when working with fence device; CAUSE: ${error}`,
    );

    return response.status(400).send();
  }

  const { parameters: agentSpecParams } = agentSpec;

  const args = Object.entries(agentSpecParams)
    .reduce<string[]>((previous, [paramId, paramSpec]) => {
      const { content_type: paramType, default: paramDefault } = paramSpec;
      const { [paramId]: rParamValue } = rParameters;

      if (
        [paramDefault, '', null, undefined].some((bad) => rParamValue === bad)
      )
        return previous;

      // TODO: add SQL modifier after finding a way to escape single quotes
      const paramValue = sanitize(rParamValue, MAP_TO_VAR_TYPE[paramType]);

      previous.push(`${paramId}="${paramValue}"`);

      return previous;
    }, [])
    .join(' ');

  stdoutVar(
    { agent, args, name },
    `Proceed to record fence device (${fenceUuid}): `,
  );

  const modifiedDate = timestamp();

  try {
    const wcode = await write(
      `INSERT INTO
        fences (
          fence_uuid,
          fence_name,
          fence_agent,
          fence_arguments,
          modified_date
        ) VALUES (
          '${fenceUuid}',
          '${name}',
          '${agent}',
          '${args}',
          '${modifiedDate}'
        ) ON CONFLICT (fence_uuid)
          DO UPDATE SET
            fence_name = '${name}',
            fence_agent = '${agent}',
            fence_arguments = '${args}',
            modified_date = '${modifiedDate}';`,
    );

    assert(wcode === 0, `Write exited with code ${wcode}`);
  } catch (error) {
    stderr(`Failed to write fence record; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const scode = rUuid ? 201 : 200;

  return response.status(scode).send();
};
