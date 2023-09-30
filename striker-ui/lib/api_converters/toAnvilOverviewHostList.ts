const toAnvilOverviewHostList = (
  data: APIAnvilOverviewArray[number]['hosts'],
): APIAnvilOverview['hosts'] =>
  data.reduce<APIAnvilOverview['hosts']>(
    (previous, { hostName: name, hostType: type, hostUUID: uuid }) => {
      previous[uuid] = { name, type, uuid };

      return previous;
    },
    {},
  );

export default toAnvilOverviewHostList;
