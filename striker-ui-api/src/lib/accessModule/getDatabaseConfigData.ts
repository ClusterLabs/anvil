import assert from 'assert';

import { getData } from './getData';
import { mutateData } from './mutateData';
import { sub } from './sub';

export const getDatabaseConfigData = async () => {
  // Empty the existing data->database hash before re-reading updated values.
  await mutateData<string>({ keys: ['database'], operator: '=', value: '{}' });

  const [code] = await sub<[string]>('read_config', {
    pre: ['Storage'],
  });

  assert(Number(code) === 0, `Subroutine failed with code ${code}`);

  return getData<AnvilDataDatabaseHash>('database');
};
