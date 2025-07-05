import {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
  INPUT_ID_UPS_TYPE,
} from './inputIds';

const getUpsFormikInitialValues = (
  template: APIUpsTemplate,
  ups?: APIUpsOverview,
) => {
  const ids = Object.keys(template);

  const typeId =
    ids.find((id) => {
      const { [id]: type } = template;

      return ups?.upsAgent === type.agent;
    }) ?? '';

  return {
    [INPUT_ID_UPS_IP]: ups?.upsIPAddress ?? '',
    [INPUT_ID_UPS_NAME]: ups?.upsName ?? '',
    [INPUT_ID_UPS_TYPE]: typeId,
  };
};

export default getUpsFormikInitialValues;
