import Grid from '@mui/material/Grid';
import { createFilterOptions } from '@mui/material/useAutocomplete';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import Autocomplete from '../Autocomplete';
import { StorageBar } from '../Bars';
import IconButton from '../IconButton';
import { BodyText, InlineMonoText, SmallText } from '../Text';

const StorageGroupMemberForm = <Values extends StorageGroupFormikValues>(
  ...[props]: Parameters<React.FC<StorageGroupMemberFormProps<Values>>>
): ReturnType<React.FC<StorageGroupMemberFormProps<Values>>> => {
  const { formikUtils, host: hostUuid, storages } = props;

  const { [hostUuid]: host } = storages.hosts;

  const { changeFieldValue, formik } = formikUtils;

  const chains = useMemo(
    () => ({
      vg: `hosts.${hostUuid}.vg`,
    }),
    [hostUuid],
  );

  const vgUuids = useMemo<string[]>(
    () =>
      Object.values(storages.volumeGroups)
        .filter((vg) => vg.host === hostUuid)
        .map((vg) => vg.uuid),
    [hostUuid, storages.volumeGroups],
  );

  return (
    <Grid alignItems="center" container spacing="1em">
      <Grid item xs>
        <Autocomplete
          filterOptions={createFilterOptions<string>({
            stringify: (uuid) => {
              const { [uuid]: vg } = storages.volumeGroups;

              return `${vg.name}\n${vg.internalUuid}`;
            },
          })}
          getOptionDisabled={(uuid) => {
            const used = !storages.unusedVolumeGroups.includes(uuid);

            const other = formik.initialValues.hosts[hostUuid].vg !== uuid;

            // Disable when the volume group is used, but exclude the initial volume group.
            return used && other;
          }}
          getOptionLabel={(uuid) => {
            const { [uuid]: vg } = storages.volumeGroups;

            return vg.name;
          }}
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

            const vgFree = dSizeStr(vg.free, { toUnit: 'ibyte' }) ?? 'none';

            const vgSize = dSizeStr(vg.size, { toUnit: 'ibyte' }) ?? 'none';

            return (
              <li {...optionProps} key={`vg-${uuid}`}>
                <Grid container rowSpacing="0.4em">
                  <Grid alignItems="center" container spacing="0.5em">
                    <Grid item xs>
                      <BodyText inheritColour noWrap>
                        {vg.name}
                      </BodyText>
                    </Grid>
                    <Grid item>
                      <BodyText inheritColour noWrap variant="caption">
                        Free
                        <InlineMonoText inheritColour>{vgFree}</InlineMonoText>/
                        <InlineMonoText inheritColour>{vgSize}</InlineMonoText>
                      </BodyText>
                    </Grid>
                  </Grid>
                  <Grid item width="100%">
                    <StorageBar thin volumeGroup={vg} />
                  </Grid>
                  <Grid item width="100%">
                    <SmallText inheritColour monospaced noWrap>
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
