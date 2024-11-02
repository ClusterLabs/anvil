import { Eject as EjectIcon } from '@mui/icons-material';
import { Box, Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { FC, useMemo } from 'react';

import Autocomplete from '../Autocomplete';
import MessageGroup from '../MessageGroup';
import { changeIsoSchema } from './schemas';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import Spinner from '../Spinner';
import { BodyText, MonoText } from '../Text';
import useFetch from '../../hooks/useFetch';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerIsoSummary: FC<ServerIsoSummaryProps> = (props) => {
  const { fileUuid } = props;

  const { data: file } = useFetch<APIFileDetail>(`/file/${fileUuid}`);

  if (!file) {
    return <Spinner mt={0} />;
  }

  const { checksum, path, size } = file;

  return (
    <Box>
      <MonoText>{path.full}</MonoText>
      <MonoText>{dSizeStr(size, { toUnit: 'ibyte' })}</MonoText>
      <MonoText>{checksum}</MonoText>
    </Box>
  );
};

const ServerChangeIsoForm: FC<ServerChangeIsoFormProps> = (props) => {
  const { detail, device } = props;

  const working = useMemo(
    () => detail.devices.disks.find((disk) => disk.target.dev === device),
    [detail.devices.disks, device],
  );

  const formikUtils = useFormikUtils<ServerChangeIsoFormikValues>({
    initialValues: {
      file: working?.source.file.uuid ?? null,
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: changeIsoSchema,
  });
  const { disabledSubmit, formik, formikErrors } = formikUtils;

  const chains = useMemo(() => ({ file: `file` }), []);

  const { data: isos } = useFetch<APIFileOverviewList>(
    `/file?anvil_uuid=${detail.anvil.uuid}&type=iso`,
    {
      refreshInterval: 5000,
    },
  );

  const isoValues = useMemo(() => isos && Object.values(isos), [isos]);

  const fieldValue = useMemo(() => {
    if (!isos) return null;

    const { file } = formik.values;

    if (!file) return null;

    return isos[file] ?? null;
  }, [formik.values, isos]);

  if (!isoValues) {
    return <Spinner mt={0} />;
  }

  return (
    <ServerFormGrid<ServerChangeIsoFormikValues> formik={formik}>
      <Grid item width="100%">
        <Autocomplete
          autoHighlight
          clearIcon={<EjectIcon />}
          clearText="Eject ISO"
          getOptionLabel={(option) => option.name}
          id={chains.file}
          isOptionEqualToValue={(option, value) => option.uuid === value.uuid}
          label="ISO (optical disk)"
          noOptionsText="No matching ISO"
          onChange={(event, value) => {
            formik.setFieldValue(chains.file, value ? value.uuid : null, true);
          }}
          openOnFocus
          options={isoValues}
          renderOption={(optionProps, option) => {
            const { name, uuid } = option;

            return (
              <li {...optionProps} key={`iso-op-${uuid}`}>
                <BodyText inheritColour>{name}</BodyText>
              </li>
            );
          }}
          value={fieldValue}
        />
      </Grid>
      {formik.values.file && (
        <Grid item width="100%">
          <ServerIsoSummary fileUuid={formik.values.file} />
        </Grid>
      )}
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ServerFormSubmit
          detail={detail}
          formDisabled={disabledSubmit}
          label="Save"
        />
      </Grid>
    </ServerFormGrid>
  );
};

export default ServerChangeIsoForm;
