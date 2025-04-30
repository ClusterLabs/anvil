import { Grid } from '@mui/material';
import { useMemo } from 'react';

import IconButton from '../IconButton';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import StorageGroupMemberForm from './StorageGroupMemberForm';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const buildFormikInitialValues = (
  storages: APIAnvilSharedStorageOverview,
  sgUuid: string,
  hostUuids: string[],
): StorageGroupFormikValues => {
  const { [sgUuid]: storageGroup } = storages.storageGroups;

  if (!storageGroup) {
    const hosts = hostUuids.reduce<
      Record<string, StorageGroupMemberFormikValues>
    >((previous, hostUuid) => {
      previous[hostUuid] = {
        vg: null,
      };

      return previous;
    }, {});

    return {
      hosts,
      name: '',
    };
  }

  const { members, name } = storageGroup;

  const hosts = Object.values(members).reduce<
    Record<string, StorageGroupMemberFormikValues>
  >((previous, member) => {
    const { [member.volumeGroup]: volumeGroup } = storages.volumeGroups;

    const { host: hostUuid, uuid: vgUuid } = volumeGroup;

    previous[hostUuid] = {
      vg: vgUuid,
    };

    return previous;
  }, {});

  return {
    hosts,
    name,
  };
};

const StorageGroupForm: React.FC<StorageGroupFormProps> = (props) => {
  const { storages, uuid: sgUuid = '' } = props;

  const hostUuids = useMemo(
    () => Object.keys(storages.hosts),
    [storages.hosts],
  );

  const vgUuids = useMemo(
    () => Object.keys(storages.volumeGroups),
    [storages.volumeGroups],
  );

  const formikUtils = useFormikUtils<StorageGroupFormikValues>({
    initialValues: buildFormikInitialValues(storages, sgUuid, hostUuids),
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
  });

  const { formik, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      name: 'name',
    }),
    [],
  );

  return (
    <Grid component="form" container spacing="1em">
      <Grid item width="100%">
        <Grid alignItems="center" container spacing="1em">
          <Grid item xs>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains.name}
                  label="Storage group name"
                  name={chains.name}
                  onChange={handleChange}
                  value={formik.values.name}
                />
              }
            />
          </Grid>
          <Grid item>
            <IconButton mapPreset="delete" size="small" />
          </Grid>
        </Grid>
      </Grid>
      {hostUuids.map((uuid) => (
        <Grid item key={`member-on-host-${uuid}`} width="100%">
          <StorageGroupMemberForm
            formikUtils={formikUtils}
            host={uuid}
            storages={storages}
            vgs={vgUuids}
          />
        </Grid>
      ))}
    </Grid>
  );
};

export default StorageGroupForm;
