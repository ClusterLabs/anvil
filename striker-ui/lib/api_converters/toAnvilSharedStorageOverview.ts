const toMemberCalcable = (
  members: Record<string, APIAnvilStorageGroupMemberCalcable>,
  sMember: APIAnvilStorageGroupMember,
): Record<string, APIAnvilStorageGroupMemberCalcable> => {
  const { uuid, volumeGroup: sVolumeGroup } = sMember;

  const { free: sFree, size: sSize, used: sUsed, ...rest } = sVolumeGroup;

  let free: bigint;
  let size: bigint;
  let used: bigint;

  try {
    free = BigInt(sFree);
    size = BigInt(sSize);
    used = BigInt(sUsed);
  } catch (error) {
    return members;
  }

  members[uuid] = {
    uuid,
    volumeGroup: {
      ...rest,
      free,
      size,
      used,
    },
  };

  return members;
};

const toStorageGroupCalcable = (
  storageGroups: Record<string, APIAnvilStorageGroupCalcable>,
  sStorageGroup: APIAnvilStorageGroup,
): Record<string, APIAnvilStorageGroupCalcable> => {
  const {
    free: sFree,
    members: sMembers,
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

  const members = Object.values(sMembers).reduce<
    Record<string, APIAnvilStorageGroupMemberCalcable>
  >(toMemberCalcable, {});

  storageGroups[uuid] = {
    ...rest,
    free,
    members,
    size,
    used,
    uuid,
  };

  return storageGroups;
};

const toAnvilSharedStorageOverview = (
  data: APIAnvilStorageList,
): APIAnvilSharedStorageOverview => {
  const { storageGroupTotals, storageGroups: sStorageGroups } = data;

  const storageGroups = Object.values(sStorageGroups).reduce<
    Record<string, APIAnvilStorageGroupCalcable>
  >(toStorageGroupCalcable, {});

  let totalFree: bigint;
  let totalSize: bigint;
  let totalUsed: bigint;

  try {
    totalFree = BigInt(storageGroupTotals.free);
    totalSize = BigInt(storageGroupTotals.size);
    totalUsed = BigInt(storageGroupTotals.used);
  } catch (error) {
    return {
      storageGroups,
      totalFree: BigInt(0),
      totalSize: BigInt(0),
      totalUsed: BigInt(0),
    };
  }

  return {
    storageGroups,
    totalFree,
    totalSize,
    totalUsed,
  };
};

export default toAnvilSharedStorageOverview;
