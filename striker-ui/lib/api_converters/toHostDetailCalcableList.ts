import toHostDetailCalcable from './toHostDetailCalcable';

const toHostDetailCalcableList = (
  list: APIHostDetailList,
): APIHostDetailCalcableList =>
  Object.values(list).reduce<APIHostDetailCalcableList>((previous, host) => {
    const { uuid } = host;

    previous[uuid] = toHostDetailCalcable(host);

    return previous;
  }, {});

export default toHostDetailCalcableList;
