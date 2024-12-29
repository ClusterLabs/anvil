const sortAnvils = (unsortedList: AnvilListItem[]): AnvilListItem[] => {
  const optimal: AnvilListItem[] = [];
  const notReady: AnvilListItem[] = [];
  const degraded: AnvilListItem[] = [];

  unsortedList.forEach((anvil) => {
    if (anvil.anvilStatus.system === 'optimal') {
      optimal.push(anvil);
    } else {
      degraded.push(anvil);
    }
  });
  return [...degraded, ...notReady, ...optimal];
};

export default sortAnvils;
