import assert from 'assert';

import { REP_UUID } from '../../consts';

import { variable } from '../../accessModule';

export const setConfigVariables = async (
  data: FormConfigData,
  source: string,
) => {
  const entries = Object.entries(data);

  for (const [key, obj] of entries) {
    const { step = 1, value } = obj;

    const uuid = await variable({
      file: __filename,
      variable_default: '',
      varaible_description: '',
      variable_name: key,
      variable_section: `config_step${step}`,
      variable_source_uuid: source,
      variable_source_table: 'hosts',
      variable_value: value,
    });

    assert(REP_UUID.test(uuid), `Failed to set variable [${key}]=[${obj}]`);
  }
};
