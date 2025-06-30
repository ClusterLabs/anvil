import MuiGrid from '@mui/material/Grid2';

import { ManifestFormContext, useManifestFormContext } from './ManifestForm';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import UncontrolledInput from '../UncontrolledInput';

import {
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
} from './inputIds';

const AnIdInputGroup: React.FC<AnIdInputGroupProps> = (props) => {
  const { slotProps } = props;

  const context = useManifestFormContext(ManifestFormContext);

  if (!context) {
    return null;
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
      {...slotProps?.container}
    >
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={INPUT_ID_AI_PREFIX}
              label="Prefix"
              name={INPUT_ID_AI_PREFIX}
              onChange={handleChange}
              required
              value={formik.values[INPUT_ID_AI_PREFIX]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={INPUT_ID_AI_DOMAIN}
              label="Domain name"
              name={INPUT_ID_AI_DOMAIN}
              onChange={handleChange}
              required
              value={formik.values[INPUT_ID_AI_DOMAIN]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={INPUT_ID_AI_SEQUENCE}
              label="Sequence"
              name={INPUT_ID_AI_SEQUENCE}
              onChange={handleChange}
              required
              value={formik.values[INPUT_ID_AI_SEQUENCE]}
            />
          }
        />
      </MuiGrid>
    </MuiGrid>
  );
};

export default AnIdInputGroup;
