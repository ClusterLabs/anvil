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

const toMemberCalcableRecord = (
  members: Record<string, APIAnvilStorageGroupMemberCalcable>,
  sMember: APIAnvilStorageGroupMember,
): Record<string, APIAnvilStorageGroupMemberCalcable> => {
  const { uuid, volumeGroup: sVolumeGroup } = sMember;

  let volumeGroup: APIAnvilVolumeGroupCalcable;

  try {
    volumeGroup = toVolumeGroupCalcable(sVolumeGroup);
  } catch (error) {
    return members;
  }

  members[uuid] = {
    uuid,
    volumeGroup,
  };

  return members;
};

const toStorageGroupCalcableRecord = (
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
  >(toMemberCalcableRecord, {});

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
      storageGroups,
      totalFree: BigInt(0),
      totalSize: BigInt(0),
      totalUsed: BigInt(0),
      volumeGroups,
    };
  }

  return {
    storageGroups,
    totalFree,
    totalSize,
    totalUsed,
    volumeGroups,
  };
};

export default toAnvilSharedStorageOverview;
