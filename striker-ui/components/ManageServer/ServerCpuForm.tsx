import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerCpuForm: FC<ServerCpuFormProps> = (props) => {
  const { detail } = props;

  const {
    cpu: { topology: cpuTopology },
  } = detail;

  const formikUtils = useFormikUtils<ServerCpuFormikValues>({
    initialValues: {
      cpu: {
        clusters: String(cpuTopology.clusters),
        cores: String(cpuTopology.cores),
        dies: String(cpuTopology.dies),
        sockets: String(cpuTopology.sockets),
        threads: String(cpuTopology.threads),
      },
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
  });
  const { disabledSubmit, formik, handleChange } = formikUtils;

  const chains = useMemo(() => {
    const base = 'cpu';

    return {
      cores: `${base}.cores`,
      sockets: `${base}.sockets`,
    };
  }, []);

  return (
    <ServerFormGrid<ServerCpuFormikValues> formik={formik}>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.cores}
              label="Cores"
              name={chains.cores}
              onChange={handleChange}
              required
              value={formik.values.cpu.cores}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.sockets}
              label="Sockets"
              name={chains.sockets}
              onChange={handleChange}
              required
              value={formik.values.cpu.sockets}
            />
          }
        />
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

export default ServerCpuForm;
