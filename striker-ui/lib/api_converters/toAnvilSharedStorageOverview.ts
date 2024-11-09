const toAnvilSharedStorageOverview = (
  data: AnvilSharedStorage,
): APIAnvilSharedStorageOverview => {
  const { storage_groups, total_free, total_size } = data;

  const totalFree = BigInt(total_free);
  const totalSize = BigInt(total_size);

  return storage_groups.reduce<APIAnvilSharedStorageOverview>(
    (previous, current) => {
      const {
        storage_group_free: rFree,
        storage_group_name: name,
        storage_group_total: rSize,
        storage_group_uuid: uuid,
      } = current;

      const free = BigInt(rFree);
      const size = BigInt(rSize);

      previous.storageGroups[uuid] = {
        free,
        name,
        size,
        used: size - free,
        uuid,
      };

      return previous;
    },
    {
      storageGroups: {},
      totalFree,
      totalSize,
      totalUsed: totalSize - totalFree,
    },
  );
};

export default toAnvilSharedStorageOverview;
