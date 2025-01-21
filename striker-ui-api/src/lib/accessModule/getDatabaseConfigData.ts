import { opGetData } from './getData';
import { access } from './instance';
import { opMutateData } from './mutateData';
import { opSub } from './sub';

export const getDatabaseConfigData = async () => {
  const [, , result] = await access.default.interact<
    [null, null, AnvilDataDatabaseHash]
  >(
    // Empty the existing data->database hash before re-reading updated values.
    opMutateData({
      keys: ['database'],
      operator: '=',
      value: '{}',
    }),
    opSub('read_config', {
      pre: ['Storage'],
    }),
    opGetData('database'),
  );

  return result;
};
