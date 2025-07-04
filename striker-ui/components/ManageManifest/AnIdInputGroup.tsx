import MuiGrid from '@mui/material/Grid2';
import { useContext } from 'react';

import { ManifestFormContext, useManifestFormContext } from './ManifestForm';
import ManifestInputContext, {
  ManifestInputContextValue,
} from './ManifestInputContext';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import guessManifestNetworks from './guessManifestNetworks';

import {
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
} from './inputIds';

const AnIdInputGroup: React.FC<AnIdInputGroupProps> = (props) => {
  const { slotProps } = props;

  const context = useManifestFormContext(ManifestFormContext);

  const inputContext = useContext<ManifestInputContextValue | null>(
    ManifestInputContext,
  );

  if (!context || !inputContext) {
    return null;
  }

  const { formik, getFieldChanged, setValuesKai } = context.formikUtils;

  const { hosts } = inputContext;

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
              onChange={(event) => {
                const { value } = event.target;

                setValuesKai({
                  debounce: true,
                  event,
                  values: (previous) => {
                    const shallow = { ...previous };

                    shallow[INPUT_ID_AI_PREFIX] = value;

                    return guessManifestNetworks({
                      getFieldChanged,
                      hosts,
                      values: shallow,
                    });
                  },
                });
              }}
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
              onChange={(event) => {
                const { value } = event.target;

                setValuesKai({
                  debounce: true,
                  event,
                  values: (previous) => {
                    const shallow = { ...previous };

                    shallow[INPUT_ID_AI_DOMAIN] = value;

                    return guessManifestNetworks({
                      getFieldChanged,
                      hosts,
                      values: shallow,
                    });
                  },
                });
              }}
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
              onChange={(event) => {
                const { value } = event.target;

                setValuesKai({
                  debounce: true,
                  event,
                  values: (previous) => {
                    const shallow = { ...previous };

                    shallow[INPUT_ID_AI_SEQUENCE] = Number(value);

                    return guessManifestNetworks({
                      getFieldChanged,
                      hosts,
                      values: shallow,
                    });
                  },
                });
              }}
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
