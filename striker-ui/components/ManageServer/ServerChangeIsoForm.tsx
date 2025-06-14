import { Eject as MuiEjectIcon } from '@mui/icons-material';
import { Box as MuiBox, Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import Autocomplete from '../Autocomplete';
import handleFormSubmit from './handleFormSubmit';
import IconButton from '../IconButton';
import MessageGroup from '../MessageGroup';
import { changeIsoSchema } from './schemas';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import Spinner from '../Spinner';
import { BodyText, MonoText } from '../Text';
import useFetch from '../../hooks/useFetch';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerIsoSummary: React.FC<ServerIsoSummaryProps> = (props) => {
  const { fileUuid } = props;

  const { data: file } = useFetch<APIFileDetail>(`/file/${fileUuid}`);

  if (!file) {
    return <Spinner mt={0} />;
  }

  const { checksum, path, size } = file;

  return (
    <MuiBox>
      <MonoText>{path.full}</MonoText>
      <MonoText>{dSizeStr(size, { toUnit: 'ibyte' })}</MonoText>
      <MonoText>md5: {checksum}</MonoText>
    </MuiBox>
  );
};

const ServerChangeIsoForm: React.FC<ServerChangeIsoFormProps> = (props) => {
  const { detail, device, tools } = props;

  const working = useMemo(
    () => detail.devices.disks.find((disk) => disk.target.dev === device),
    [detail.devices.disks, device],
  );

  const { data: isos } = useFetch<APIFileOverviewList>(
    `/file?name=${detail.anvil.name}&type=iso`,
    {
      refreshInterval: 5000,
    },
  );

  const formikUtils = useFormikUtils<ServerChangeIsoFormikValues>({
    initialValues: {
      file: working?.source.file.uuid ?? null,
    },
    onSubmit: (values, helpers) => {
      handleFormSubmit(
        values,
        helpers,
        tools,
        () => `/server/${detail.uuid}/change-iso`,
        () => `${values.file ? 'Insert' : 'Eject'} ISO?`,
        {
          buildSummary: (v) => {
            const { file } = v;

            const dev = working?.target.dev;

            if (!file) {
              return { device: dev };
            }

            return {
              device: dev,
              iso: isos?.[file]?.name,
            };
          },
          buildRequestBody: (v, s) => {
            if (s?.iso && v.file) {
              s.iso = v.file;
            }

            return s;
          },
        },
      );
    },
    validationSchema: changeIsoSchema,
  });
  const { disabledSubmit, formik, formikErrors } = formikUtils;

  const chains = useMemo(() => ({ file: `file` }), []);

  const isoValues = useMemo(() => isos && Object.values(isos), [isos]);

  const fieldValue = useMemo(() => {
    if (!isos) return undefined;

    const { file } = formik.values;

    if (!file) return undefined;

    return isos[file];
  }, [formik.values, isos]);

  if (!isoValues) {
    return <Spinner mt={0} />;
  }

  return (
    <ServerFormGrid<ServerChangeIsoFormikValues> formik={formik}>
      <Grid item xs>
        <Autocomplete
          disableClearable
          extendRenderInput={(inputProps) => {
            inputProps.inputLabelProps = {
              ...inputProps.inputLabelProps,

              shrink: true,
            };

            inputProps.inputProps = {
              ...inputProps.inputProps,

              notched: true,
              placeholder: 'Empty slot',
            };
          }}
          getOptionLabel={(option) => option.name}
          id={chains.file}
          isOptionEqualToValue={(option, value) => option.uuid === value?.uuid}
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
      <Grid item alignSelf="center">
        <IconButton
          onClick={() => {
            formik.setFieldValue(chains.file, null, true);
          }}
          size="small"
        >
          <MuiEjectIcon />
        </IconButton>
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
