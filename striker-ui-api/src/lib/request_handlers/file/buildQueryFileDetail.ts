import { DELETED } from '../../consts';

import join from '../../join';
import { poutvar } from '../../shell';

export const buildQueryFileDetail = ({
  fileUUIDs = ['*'],
}: {
  fileUUIDs?: string[] | '*';
}) => {
  const condFileUUIDs = ['all', '*'].includes(fileUUIDs[0])
    ? ''
    : join(fileUUIDs, {
        beforeReturn: (toReturn) =>
          toReturn ? `AND fil.file_uuid IN (${toReturn})` : '',
        elementWrapper: "'",
        separator: ', ',
      });

  poutvar({ condFileUUIDs });

  return `
    SELECT
      fil.file_uuid,
      fil.file_name,
      fil.file_size,
      fil.file_type,
      fil.file_md5sum,
      fil_loc.file_location_uuid,
      fil_loc.file_location_active,
      anv.anvil_uuid,
      anv.anvil_name,
      anv.anvil_description,
      hos.host_uuid,
      hos.host_name,
      hos.host_type
    FROM files AS fil
    JOIN file_locations AS fil_loc
      ON fil.file_uuid = fil_loc.file_location_file_uuid
    JOIN anvils AS anv
      ON fil_loc.file_location_host_uuid IN (
        anv.anvil_node1_host_uuid,
        anv.anvil_node2_host_uuid,
        anv.anvil_dr1_host_uuid
      )
    JOIN hosts AS hos
      ON fil_loc.file_location_host_uuid = hos.host_uuid
    WHERE fil.file_type != '${DELETED}'
      ${condFileUUIDs}
    ORDER BY fil.file_name ASC;`;
};
