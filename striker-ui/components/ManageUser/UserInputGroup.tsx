import MuiGrid from '@mui/material/Grid2';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import MessageBox from '../MessageBox';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import { UserFormContext, useUserFormContext } from './UserForm';

import {
  INPUT_ID_USER_CONFIRM_PASSWORD,
  INPUT_ID_USER_NAME,
  INPUT_ID_USER_PASSWORD,
} from './inputIds';

type UserInputGroupProps = {
  readonlyName?: boolean;
  requirePassword?: boolean;
};

const UserInputGroup: React.FC<UserInputGroupProps> = (props) => {
  const { readonlyName, requirePassword = true } = props;

  const context = useUserFormContext(UserFormContext);

  if (!context) {
    return <MessageBox type="error">Missing form context.</MessageBox>;
  }

  const { formik, handleChange } = context.formikUtils;

  return (
    <MuiGrid
      columns={{
        xs: 1,
        sm: 2,
        md: 3,
      }}
      container
      spacing="1em"
      width="100%"
    >
      <MuiGrid
        size={{
          xs: 1,
          sm: 2,
          md: 1,
        }}
      >
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              disableAutofill
              id={INPUT_ID_USER_NAME}
              inputProps={{
                disabled: readonlyName,
              }}
              label="Username"
              name={INPUT_ID_USER_NAME}
              onChange={handleChange}
              required
              value={formik.values[INPUT_ID_USER_NAME]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              disableAutofill
              id={INPUT_ID_USER_PASSWORD}
              label="Password"
              name={INPUT_ID_USER_PASSWORD}
              onChange={handleChange}
              required={requirePassword}
              type={INPUT_TYPES.password}
              value={formik.values[INPUT_ID_USER_PASSWORD]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              disableAutofill
              id={INPUT_ID_USER_CONFIRM_PASSWORD}
              label="Confirm password"
              name={INPUT_ID_USER_CONFIRM_PASSWORD}
              onChange={handleChange}
              required={Boolean(formik.values[INPUT_ID_USER_PASSWORD])}
              type={INPUT_TYPES.password}
              value={formik.values[INPUT_ID_USER_CONFIRM_PASSWORD]}
            />
          }
        />
      </MuiGrid>
    </MuiGrid>
  );
};

export type { UserInputGroupProps };

export default UserInputGroup;
