const toVolumeGroupCalcable = (sVolumeGroup: APIAnvilVolumeGroup) => {
  const { free: sFree, size: sSize, used: sUsed, uuid, ...rest } = sVolumeGroup;

  const free = BigInt(sFree);
  const size = BigInt(sSize);
  const used = BigInt(sUsed);

  return {
    ...rest,
    free,
    size,
    used,
    uuid,
  };
};

const toStorageGroupCalcableRecord = (
  storageGroups: Record<string, APIAnvilStorageGroupCalcable>,
  sStorageGroup: APIAnvilStorageGroup,
): Record<string, APIAnvilStorageGroupCalcable> => {
  const {
    free: sFree,
    size: sSize,
    used: sUsed,
    uuid,
    ...rest
  } = sStorageGroup;

  let free: bigint;
  let size: bigint;
  let used: bigint;

  try {
    free = BigInt(sFree);
    size = BigInt(sSize);
    used = BigInt(sUsed);
  } catch (error) {
    return storageGroups;
  }

  storageGroups[uuid] = {
    ...rest,
    free,
    size,
    used,
    uuid,
  };

  return storageGroups;
};

const toVolumeGroupCalcableRecord = (
  volumeGroups: Record<string, APIAnvilVolumeGroupCalcable>,
  sVolumeGroup: APIAnvilVolumeGroup,
) => {
  const { uuid } = sVolumeGroup;

  let volumeGroup: APIAnvilVolumeGroupCalcable;

  try {
    volumeGroup = toVolumeGroupCalcable(sVolumeGroup);
  } catch (error) {
    return volumeGroups;
  }

  volumeGroups[uuid] = volumeGroup;

  return volumeGroups;
};

const toAnvilSharedStorageOverview = (
  data: APIAnvilStorageList,
): APIAnvilSharedStorageOverview => {
  const {
    storageGroupTotals,
    storageGroups: sStorageGroups,
    volumeGroups: sVolumeGroups,
    ...rest
  } = data;

  const storageGroups = Object.values(sStorageGroups).reduce<
    Record<string, APIAnvilStorageGroupCalcable>
  >(toStorageGroupCalcableRecord, {});

  const volumeGroups = Object.values(sVolumeGroups).reduce<
    Record<string, APIAnvilVolumeGroupCalcable>
  >(toVolumeGroupCalcableRecord, {});

  let totalFree: bigint;
  let totalSize: bigint;
  let totalUsed: bigint;

  try {
    totalFree = BigInt(storageGroupTotals.free);
    totalSize = BigInt(storageGroupTotals.size);
    totalUsed = BigInt(storageGroupTotals.used);
  } catch (error) {
    return {
      ...rest,
      storageGroups,
      totalFree: BigInt(0),
      totalSize: BigInt(0),
      totalUsed: BigInt(0),
      volumeGroups,
    };
  }

  return {
    ...rest,
    storageGroups,
    totalFree,
    totalSize,
    totalUsed,
    volumeGroups,
  };
};

export default toAnvilSharedStorageOverview;
