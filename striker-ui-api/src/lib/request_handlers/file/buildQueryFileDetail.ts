import join from '../../join';

const buildQueryFileDetail = ({
  filesUUID,
}: {
  filesUUID?: string[] | '*';
}) => {
  const condFilesUUID = join(filesUUID, {
    beforeReturn: (toReturn) =>
      toReturn ? `AND fil.file_uuid IN (${toReturn})` : '',
    elementWrapper: "'",
    separator: ', ',
  });

  console.log(`condFilesUUID=[${condFilesUUID}]`);

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
      anv.anvil_description
    FROM files AS fil
    JOIN file_locations AS fil_loc
      ON fil.file_uuid = fil_loc.file_location_file_uuid
    JOIN anvils AS anv
      ON fil_loc.file_location_anvil_uuid = anv.anvil_uuid
    WHERE fil.file_type != 'DELETED'
      ${condFilesUUID};`;
};

export default buildQueryFileDetail;