const toAnvilDetail = (data: AnvilListItem): APIAnvilDetail => {
  const {
    anvilStatus,
    anvil_name: anvilName,
    anvil_uuid: anvilUuid,
    hosts: rHosts,
  } = data;

  const hosts = rHosts.reduce<APIAnvilDetail['hosts']>((previous, current) => {
    const {
      host_name: hostName,
      host_uuid: hostUuid,
      maintenance_mode: maintenance,
      server_count: serverCount,
      state,
      state_percent: stateProgress,
    } = current;

    previous[hostUuid] = {
      name: hostName,
      maintenance,
      serverCount,
      state,
      stateProgress,
      uuid: hostUuid,
    };

    return previous;
  }, {});

  return {
    hosts,
    name: anvilName,
    status: anvilStatus,
    uuid: anvilUuid,
  };
};

export default toAnvilDetail;
