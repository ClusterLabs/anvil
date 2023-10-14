import toAnvilOverviewHostList from './toAnvilOverviewHostList';

const toAnvilOverviewList = (
  data: APIAnvilOverviewArray,
): APIAnvilOverviewList =>
  data.reduce<APIAnvilOverviewList>(
    (
      previous,
      {
        anvilDescription: description,
        anvilName: name,
        anvilUUID: uuid,
        hosts,
      },
    ) => {
      previous[uuid] = {
        description,
        hosts: toAnvilOverviewHostList(hosts),
        name,
        uuid,
      };

      return previous;
    },
    {},
  );

export default toAnvilOverviewList;
