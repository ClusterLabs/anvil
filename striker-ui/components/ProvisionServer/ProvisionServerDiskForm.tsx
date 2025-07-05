import Grid from '@mui/material/Grid';
import { createFilterOptions } from '@mui/material/useAutocomplete';
import { DataSize, dSize, dSizeStr } from 'format-data-size';
import { useCallback, useMemo } from 'react';

import { DSIZE_SELECT_ITEMS } from '../../lib/consts/DSIZES';

import Autocomplete from '../Autocomplete';
import MaxButton from './MaxButton';
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';

const ProvisionServerDiskForm: React.FC<ProvisionServerDiskProps> = (props) => {
  const { formikUtils, id, resources, scope } = props;

  const { changeFieldValue, formik, handleChange } = formikUtils;

  const chains = useMemo(() => {
    const base = `disks.${id}`;

    const size = `${base}.size`;

    return {
      size,
      unit: `${size}.unit`,
      value: `${size}.value`,
      storageGroup: `${base}.storageGroup`,
    };
  }, [id]);

  const storageGroups = useMemo(
    () => ({
      uuids: Object.keys(resources.storageGroups),
    }),
    [resources.storageGroups],
  );

  const getBranch = useCallback(
    (uuid: string) => {
      const { [uuid]: sg } = resources.storageGroups;

      const { [sg.node]: node } = resources.nodes;

      return {
        node,
        sg,
      };
    },
    [resources.nodes, resources.storageGroups],
  );

  const diskValues = formik.values.disks[id];

  const maxFreeStorage = useMemo(
    () =>
      scope.reduce<bigint>((previous, group) => {
        const { storageGroup: uuid } = group;

        const sg = resources.storageGroups[uuid];

        return sg.usage.free > previous ? sg.usage.free : previous;
      }, BigInt(0)),
    [resources.storageGroups, scope],
  );

  const maxFreeStorageReadable = useMemo<DataSize & { str: string }>(() => {
    const size = dSize(maxFreeStorage, {
      toUnit: diskValues.size.unit,
    });

    if (!size) {
      return {
        str: 'unknown',
        unit: 'B',
        value: '0',
      };
    }

    return {
      ...size,
      str: `${size.value} ${size.unit}`,
    };
  }, [diskValues.size.unit, maxFreeStorage]);

  return (
    <Grid container spacing="1em">
      <Grid item width="100%">
        <UncontrolledInput
          input={
            <OutlinedLabeledInputWithSelect
              id={chains.size}
              label={`Disk ${id}: size`}
              inputWithLabelProps={{
                id: chains.value,
                inputProps: {
                  endAdornment: (
                    <MaxButton
                      onClick={() => {
                        changeFieldValue(
                          chains.value,
                          maxFreeStorageReadable.value,
                          true,
                        );
                      }}
                    >
                      {maxFreeStorageReadable.str}
                    </MaxButton>
                  ),
                },
                name: chains.value,
                required: true,
              }}
              onChange={handleChange}
              selectItems={DSIZE_SELECT_ITEMS}
              selectWithLabelProps={{
                id: chains.unit,
                name: chains.unit,
                onChange: formik.handleChange,
                value: diskValues.size.unit,
              }}
              value={diskValues.size.value}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <Autocomplete
          filterOptions={createFilterOptions<string>({
            ignoreCase: true,
            stringify: (uuid) => {
              const { node, sg } = getBranch(uuid);

              return `${sg.name}\n${node.name}`;
            },
          })}
          getOptionDisabled={(uuid) =>
            scope.every((group) => group.storageGroup !== uuid)
          }
          getOptionLabel={(uuid) => {
            const { node, sg } = getBranch(uuid);

            return `${sg.name} (${node.name})`;
          }}
          id={chains.storageGroup}
          isOptionEqualToValue={(uuid, value) => uuid === value}
          label={`Disk ${id}: storage group`}
          noOptionsText="No matching storage group"
          onChange={(event, value) => {
            changeFieldValue(chains.storageGroup, value, true);
          }}
          openOnFocus
          options={storageGroups.uuids}
          renderOption={(optionProps, uuid) => {
            const { node, sg } = getBranch(uuid);

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
          required
          value={diskValues.storageGroup}
        />
      </Grid>
    </Grid>
  );
};

export default ProvisionServerDiskForm;
