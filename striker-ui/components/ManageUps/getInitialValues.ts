import {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
  INPUT_ID_UPS_TYPE,
} from './inputIds';

const getUpsFormikInitialValues = (
  template: APIUpsTemplate,
  detail?: APIUpsOverview[string],
) => {
  const ids = Object.keys(template);

  const typeId =
    ids.find((id) => {
      const { [id]: type } = template;

      return detail?.upsAgent === type.agent;
    }) ?? '';

  return {
    [INPUT_ID_UPS_IP]: detail?.upsIPAddress ?? '',
    [INPUT_ID_UPS_NAME]: detail?.upsName ?? '',
    [INPUT_ID_UPS_TYPE]: typeId,
  };
};

export default getUpsFormikInitialValues;
