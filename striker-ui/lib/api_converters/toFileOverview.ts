const toFileOverviewList = (rows: string[][]) =>
  rows.reduce<APIFileOverviewList>((previous, row) => {
    const [uuid, name, size, type, checksum] = row;

    previous[uuid] = {
      checksum,
      name,
      size,
      type: type as FileType,
      uuid,
    };

    return previous;
  }, {});

export default toFileOverviewList;
