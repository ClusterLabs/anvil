import { createFilterOptions, Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { DSIZE_SELECT_ITEMS } from '../../lib/consts/DSIZES';

import Autocomplete from '../Autocomplete';
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';

const ProvisionServerDiskForm: React.FC<ProvisionServerDiskProps> = (props) => {
  const { formikUtils, id, resources, storageGroups } = props;

  const { formik, handleChange } = formikUtils;

  const chains = useMemo(() => {
    const base = `disks.${id}`;

    return {
      unit: `${base}.size.unit`,
      value: `${base}.size.value`,
      storageGroup: `${base}.storageGroup`,
    };
  }, [id]);

  const diskValues = formik.values.disks[id];

  return (
    <Grid container spacing="1em">
      <Grid item width="100%">
        <UncontrolledInput
          input={
            <OutlinedLabeledInputWithSelect
              id={chains.value}
              label={`Disk ${id}: size`}
              inputWithLabelProps={{
                id: chains.value,
                name: chains.value,
                onChange: handleChange,
                value: diskValues.size.value,
              }}
              selectItems={DSIZE_SELECT_ITEMS}
              selectWithLabelProps={{
                id: chains.unit,
                name: chains.unit,
                onChange: formik.handleChange,
                value: diskValues.size.unit,
              }}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <Autocomplete
          filterOptions={createFilterOptions<string>({
            ignoreCase: true,
            stringify: (uuid) => {
              const { [uuid]: sg } = resources.storageGroups;
              const { [sg.node]: node } = resources.nodes;

              return `${sg.name}\n${node.name}`;
            },
          })}
          getOptionLabel={(uuid) => {
            const { [uuid]: sg } = resources.storageGroups;
            const { [sg.node]: node } = resources.nodes;

            return `${sg.name} (${node.name})`;
          }}
          id={chains.storageGroup}
          isOptionEqualToValue={(uuid, value) => uuid === value}
          label={`Disk ${id}: storage group`}
          noOptionsText="No matching storage group"
          onChange={(event, value) => {
            formik.setFieldValue(chains.storageGroup, value, true);
          }}
          openOnFocus
          options={storageGroups.uuids}
          renderOption={(optionProps, uuid) => {
            const { [uuid]: sg } = resources.storageGroups;
            const { [sg.node]: node } = resources.nodes;

            return (
              <li {...optionProps} key={`storage-group-op-${uuid}`}>
                <Grid alignItems="center" container>
                  <Grid item xs>
                    <BodyText inheritColour noWrap>
                      {sg.name}
                    </BodyText>
                    <BodyText inheritColour noWrap>
                      {node.name}
                    </BodyText>
                  </Grid>
                  <Grid item>
                    <BodyText inheritColour noWrap>
                      {dSizeStr(sg.usage.free, { toUnit: 'ibyte' })} free
                    </BodyText>
                  </Grid>
                </Grid>
              </li>
            );
          }}
          value={diskValues.storageGroup}
        />
      </Grid>
    </Grid>
  );
};

export default ProvisionServerDiskForm;
