const toFileDetail = (rows: string[][]) => {
  const { 0: first } = rows;

  if (!first) return undefined;

  const [uuid, name, size, type, checksum] = first;

  return rows.reduce<APIFileDetail>(
    (previous, row) => {
      const {
        5: locationUuid,
        6: locationActive,
        7: anvilUuid,
        8: anvilName,
        9: anvilDescription,
        10: hostUuid,
        11: hostName,
        12: hostType,
      } = row;

      if (!previous.anvils[anvilUuid]) {
        previous.anvils[anvilUuid] = {
          description: anvilDescription,
          locationUuids: [],
          name: anvilName,
          uuid: anvilUuid,
        };
      }

      if (!previous.hosts[hostUuid]) {
        previous.hosts[hostUuid] = {
          locationUuids: [],
          name: hostName,
          type: hostType,
          uuid: hostUuid,
        };
      }

      if (hostType === 'dr') {
        previous.hosts[hostUuid].locationUuids.push(locationUuid);
      } else {
        previous.anvils[anvilUuid].locationUuids.push(locationUuid);
      }

      const active = Number(locationActive) === 1;

      previous.locations[locationUuid] = {
        anvilUuid,
        active,
        hostUuid,
        uuid: locationUuid,
      };

      return previous;
    },
    {
      anvils: {},
      checksum,
      hosts: {},
      locations: {},
      name,
      size,
      type: type as FileType,
      uuid,
    },
  );
};

export default toFileDetail;
