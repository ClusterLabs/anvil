import assert from 'assert';

import { DELETED } from '../../consts';

import { timestamp, write } from '../../accessModule';

export const deleteConfigVariables = async (source: string) => {
  const modifiedDate = timestamp();

  const sql = `
    UPDATE
      variables
    SET
      variable_value = '${DELETED}',
      modified_date  = '${modifiedDate}'
    WHERE
        variable_name LIKE 'form::config_step%'
      AND
        variable_source_uuid = '${source}'
      AND
        variable_source_table = 'hosts';`;

  const wcode = await write(sql);

  assert(wcode === 0, `Write exited with code ${wcode}`);
};
