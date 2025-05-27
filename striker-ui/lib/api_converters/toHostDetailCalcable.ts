import toStorageCalcable from './toStorageCalcable';

const toHostDetailCalcable = (detail: APIHostDetail): APIHostDetailCalcable => {
  const { storage, ...restDetail } = detail;

  const vgs = Object.values(storage.volumeGroups);

  const volumeGroups = vgs.reduce<Record<string, APIAnvilVolumeGroupCalcable>>(
    (previous, vg) => {
      previous[vg.uuid] = toStorageCalcable(vg);

      return previous;
    },
    {},
  );

  const volumeGroupTotals = toStorageCalcable(storage.volumeGroupTotals);

  return {
    ...restDetail,
    storage: {
      volumeGroups,
      volumeGroupTotals,
    },
  };
};

export default toHostDetailCalcable;
