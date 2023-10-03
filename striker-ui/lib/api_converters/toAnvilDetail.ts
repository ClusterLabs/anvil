const toAnvilDetail = (data: AnvilListItem): APIAnvilDetail => {
  const {
    anvil_name: anvilName,
    anvil_state: anvilState,
    anvil_uuid: anvilUuid,
    hosts: rHosts,
  } = data;

  const hosts = rHosts.reduce<APIAnvilDetail['hosts']>((previous, current) => {
    const {
      host_name: hostName,
      host_uuid: hostUuid,
      maintenance_mode: maintenance,
      state,
      state_percent: stateProgress,
    } = current;

    previous[hostUuid] = {
      name: hostName,
      maintenance,
      state,
      stateProgress,
      uuid: hostUuid,
    };

    return previous;
  }, {});

  return {
    hosts,
    name: anvilName,
    state: anvilState,
    uuid: anvilUuid,
  };
};

export default toAnvilDetail;
