const toAnvilOverviewHostList = (
  data: APIAnvilOverviewArray[number]['hosts'],
): APIAnvilOverview['hosts'] =>
  data.reduce<APIAnvilOverview['hosts']>((previous, host) => {
    const {
      hostName: name,
      hostType: type,
      hostUUID: uuid,
      shortHostName: short,
    } = host;

    previous[uuid] = {
      name,
      short,
      type,
      uuid,
    };

    return previous;
  }, {});

export default toAnvilOverviewHostList;
