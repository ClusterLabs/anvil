const sortAnvils = (unsortedList: AnvilListItem[]): AnvilListItem[] => {
  const optimal: AnvilListItem[] = [];
  const notReady: AnvilListItem[] = [];
  const degraded: AnvilListItem[] = [];

  unsortedList.forEach((anvil) => {
    if (anvil.anvil_state === 'optimal') optimal.push(anvil);
    else if (anvil.anvil_state === 'not_ready') notReady.push(anvil);
    else degraded.push(anvil);
  });
  return [...degraded, ...notReady, ...optimal];
};

export default sortAnvils;
