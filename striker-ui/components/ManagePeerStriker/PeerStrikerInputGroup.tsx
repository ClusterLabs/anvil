import MuiGrid from '@mui/material/Grid2';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import CheckboxWithLabel from '../CheckboxWithLabel';
import MessageBox from '../MessageBox';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import {
  PeerStrikerFormContext,
  usePeerStrikerFormContext,
} from './PeerStrikerForm';
import UncontrolledInput from '../UncontrolledInput';

import {
  INPUT_ID_PEER_STRIKER_PASSWORD,
  INPUT_ID_PEER_STRIKER_PING_TEST,
  INPUT_ID_PEER_STRIKER_TARGET,
} from './inputIds';

const PeerStrikerInputGroup: React.FC = () => {
  const context = usePeerStrikerFormContext(PeerStrikerFormContext);

  if (!context) {
    return <MessageBox type="error">Missing form context.</MessageBox>;
  }

  const { formik, handleChange } = context.formikUtils;

  return (
    <MuiGrid
      columns={{
        xs: 1,
        sm: 2,
      }}
      container
      spacing="1em"
      width="100%"
    >
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              disableAutofill
              id={INPUT_ID_PEER_STRIKER_TARGET}
              label="Target"
              name={INPUT_ID_PEER_STRIKER_TARGET}
              onChange={handleChange}
              required
              value={formik.values[INPUT_ID_PEER_STRIKER_TARGET]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              disableAutofill
              id={INPUT_ID_PEER_STRIKER_PASSWORD}
              label="Password"
              name={INPUT_ID_PEER_STRIKER_PASSWORD}
              onChange={handleChange}
              type={INPUT_TYPES.password}
              value={formik.values[INPUT_ID_PEER_STRIKER_PASSWORD]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid>
        <CheckboxWithLabel
          checked={formik.values[INPUT_ID_PEER_STRIKER_PING_TEST]}
          id={INPUT_ID_PEER_STRIKER_PING_TEST}
          label="Ping"
          name={INPUT_ID_PEER_STRIKER_PING_TEST}
          onChange={formik.handleChange}
        />
      </MuiGrid>
    </MuiGrid>
  );
};

export default PeerStrikerInputGroup;
