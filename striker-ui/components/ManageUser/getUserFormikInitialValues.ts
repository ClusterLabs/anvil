import {
  INPUT_ID_USER_CONFIRM_PASSWORD,
  INPUT_ID_USER_NAME,
  INPUT_ID_USER_PASSWORD,
} from './inputIds';

const getUserFormikInitialValues = (user?: APIUserOverview) => ({
  [INPUT_ID_USER_CONFIRM_PASSWORD]: '',
  [INPUT_ID_USER_NAME]: user?.userName ?? '',
  [INPUT_ID_USER_PASSWORD]: '',
});

export default getUserFormikInitialValues;
