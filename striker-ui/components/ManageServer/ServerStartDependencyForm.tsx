import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import handleFormSubmit from './handleFormSubmit';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { startDependencySchema } from './schemas';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import SwitchWithLabel from '../SwitchWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerStartDependencyForm: FC<ServerStartDependencyFormProps> = (
  props,
) => {
  const { detail, servers, tools } = props;

  const formikUtils = useFormikUtils<ServerStartDependencyFormikValues>({
    initialValues: {
      active: detail.start.active,
      after: detail.start.after || '',
      delay: String(detail.start.delay),
    },
    onSubmit: (values, helpers) => {
      handleFormSubmit(
        values,
        helpers,
        tools,
        () => `/server/${detail.uuid}/set-start-dependency`,
        () => `Set start dependency?`,
        {
          buildSummary: (v) => {
            const { active, after, delay } = v;

            if (!active) {
              return {
                'stay-off': 'yes',
              };
            }

            return {
              after: servers[after]?.name,
              delay: `${delay} second(s)`,
            };
          },
          buildRequestBody: (v) => {
            const { active, after, delay } = v;

            if (active && after) {
              return {
                after,
                delay: Number(delay),
              };
            }

            return { active };
          },
        },
      );
    },
    validationSchema: startDependencySchema,
  });

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      active: `active`,
      after: `after`,
      delay: `delay`,
    }),
    [],
  );

  const filteredServerValues = useMemo(
    () =>
      Object.values(servers).filter((server) => server.uuid !== detail.uuid),
    [detail.uuid, servers],
  );

  const serverOptions = useMemo<SelectItem[]>(
    () =>
      filteredServerValues.map<SelectItem>(({ name, uuid }) => ({
        displayValue: name,
        value: uuid,
      })),
    [filteredServerValues],
  );

  return (
    <ServerFormGrid<ServerStartDependencyFormikValues> formik={formik}>
      <Grid item xs={1}>
        <SelectWithLabel
          id={chains.after}
          label="Start after"
          name={chains.after}
          onChange={formik.handleChange}
          selectItems={serverOptions}
          selectProps={{
            disabled: !formik.values.active,
            onClearIndicatorClick: () => {
              formik.setFieldValue(chains.after, '', true);
            },
          }}
          value={formik.values.after}
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.delay}
              inputProps={{
                disabled: !formik.values.active || formik.values.after === '',
              }}
              label="Delay (seconds)"
              name={chains.delay}
              onChange={handleChange}
              value={formik.values.delay}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <SwitchWithLabel
          checked={!formik.values.active}
          id={chains.active}
          label="Stay off"
          name={chains.active}
          onChange={(event, checked) => {
            formik.setFieldValue(chains.active, !checked, true);
          }}
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

export default ServerStartDependencyForm;
