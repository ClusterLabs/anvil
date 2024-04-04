import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_PEACEFUL_STRING } from '../../consts';

import { getFenceSpec, timestamp, write } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr, poutvar, uuid } from '../../shell';

const handleNumberType = (v: unknown) =>
  String(sanitize(v, 'number', { modifierType: 'sql' }));

const handleStringType = (v: unknown) =>
  sanitize(v, 'string', { modifierType: 'sql' });

const MAP_TO_VAR_TYPE: Record<
  AnvilDataFenceParameterType,
  (v: unknown) => string
> = {
  boolean: (v) => (sanitize(v, 'boolean') ? '1' : ''),
  integer: handleNumberType,
  second: handleNumberType,
  select: handleStringType,
  string: handleStringType,
};

export const createFence: RequestHandler<
  { uuid?: string },
  undefined,
  {
    agent: string;
    name: string;
    parameters: { [parameterId: string]: string };
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
    perr(`Failed to get fence devices specification; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const agent = sanitize(rAgent, 'string', { modifierType: 'sql' });
  const name = sanitize(rName, 'string', { modifierType: 'sql' });
  const fenceUuid = sanitize(rUuid, 'string', {
    fallback: uuid(),
    modifierType: 'sql',
  });

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
      const paramValue = MAP_TO_VAR_TYPE[paramType](rParamValue);

      previous.push(`${paramId}="${paramValue}"`);

      return previous;
    }, [])
    .join(' ');

  poutvar(
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
    perr(`Failed to write fence record; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const scode = rUuid ? 200 : 201;

  return response.status(scode).send();
};
