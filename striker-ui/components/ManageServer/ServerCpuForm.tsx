import { Grid } from '@mui/material';
import { useMemo } from 'react';

import handleFormSubmit from './handleFormSubmit';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { cpuSchema } from './schemas';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFetch from '../../hooks/useFetch';
import useFormikUtils from '../../hooks/useFormikUtils';

const BaseServerCpuForm: React.FC<BaseServerCpuFormProps> = (props) => {
  const { cpu, detail, tools } = props;

  const { topology: cpuTopology } = detail.cpu;

  const formikUtils = useFormikUtils<ServerCpuFormikValues>({
    initialValues: {
      clusters: String(cpuTopology.clusters),
      cores: String(cpuTopology.cores),
      dies: String(cpuTopology.dies),
      sockets: String(cpuTopology.sockets),
      threads: String(cpuTopology.threads),
    },
    onSubmit: (values, helper) => {
      handleFormSubmit(
        values,
        helper,
        tools,
        () => `/server/${detail.uuid}/set-cpu`,
        () => `Set CPU?`,
        {
          buildSummary: (v) => ({
            cores: Number(v.cores),
            sockets: Number(v.sockets),
          }),
        },
      );
    },
    validationSchema: cpuSchema,
  });
  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      cores: `cores`,
      sockets: `sockets`,
    }),
    [],
  );

  return (
    <ServerFormGrid<ServerCpuFormikValues> formik={formik}>
      <Grid item width="100%">
        <BodyText>Model: {Object.values(cpu.hosts)[0].model}</BodyText>
        <BodyText>Available cores: {cpu.cores}</BodyText>
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.cores}
              label="Cores"
              name={chains.cores}
              onChange={handleChange}
              required
              value={formik.values.cores}
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
              value={formik.values.sockets}
            />
          }
        />
      </Grid>
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

const ServerCpuForm: React.FC<ServerCpuFormProps> = (props) => {
  const { detail } = props;

  const { data: cpu } = useFetch<AnvilCPU>(`/anvil/${detail.anvil.uuid}/cpu`, {
    refreshInterval: 5000,
  });

  if (!cpu) {
    return <Spinner mt={0} />;
  }

  return <BaseServerCpuForm cpu={cpu} {...props} />;
};

export default ServerCpuForm;
