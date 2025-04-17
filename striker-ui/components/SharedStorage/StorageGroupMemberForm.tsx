import { Grid } from '@mui/material';
import { useMemo } from 'react';

import Autocomplete from '../Autocomplete';
import IconButton from '../IconButton';
import { BodyText, SmallText } from '../Text';

const StorageGroupMemberForm = <Values extends StorageGroupFormikValues>(
  ...[props]: Parameters<React.FC<StorageGroupMemberFormProps<Values>>>
): ReturnType<React.FC<StorageGroupMemberFormProps<Values>>> => {
  const { formikUtils, host: hostUuid, storages, vgs: vgUuids } = props;

  const { [hostUuid]: host } = storages.hosts;

  const { changeFieldValue, formik } = formikUtils;

  const chains = useMemo(
    () => ({
      vg: `hosts.${hostUuid}.vg`,
    }),
    [hostUuid],
  );

  return (
    <Grid alignItems="center" container spacing="1em">
      <Grid item xs>
        <Autocomplete
          getOptionDisabled={(value) =>
            !storages.unusedVolumeGroups.includes(value)
          }
          id={chains.vg}
          label={`${host.short} volume group`}
          noOptionsText="No volume group(s) available"
          onChange={(event, value) => {
            changeFieldValue(chains.vg, value, true);
          }}
          openOnFocus
          options={vgUuids}
          renderOption={(optionProps, uuid) => {
            const { [uuid]: vg } = storages.volumeGroups;

            return (
              <li {...optionProps} key={`vg-${uuid}`}>
                <Grid container>
                  <Grid item width="100%">
                    <BodyText inheritColour>{vg.name}</BodyText>
                  </Grid>
                  <Grid item width="100%">
                    <SmallText inheritColour monospaced>
                      {vg.internalUuid}
                    </SmallText>
                  </Grid>
                </Grid>
              </li>
            );
          }}
          value={formik.values.hosts[hostUuid].vg}
        />
      </Grid>
      <Grid item>
        <IconButton
          mapPreset="delete"
          onClick={() => {
            changeFieldValue(chains.vg, null, true);
          }}
          size="small"
        />
      </Grid>
    </Grid>
  );
};

export default StorageGroupMemberForm;
