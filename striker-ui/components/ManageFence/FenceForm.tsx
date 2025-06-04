import { Box, Grid } from '@mui/material';
import { capitalize } from 'lodash';
import { useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import Autocomplete from '../Autocomplete';
import convertFenceParameterToString from './convertFenceParameterToString';
import FenceParameterInput from './FenceParameterInput';
import FormSummary from '../FormSummary';
import groupFenceParameters from './groupFenceParameters';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { ExpandablePanel } from '../Panels';
import { buildFenceSchema } from './schemas';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

type FenceFormOptionalProps = {
  fence?: APIFenceOverview;
};

type FenceFormProps = FenceFormOptionalProps & {
  fences: APIFenceOverviewList;
  template: APIFenceTemplate;
  tools: CrudListFormTools;
};

const buildFormikFenceParameters = (
  spec: APIFenceSpec,
  existing?: APIFenceOverview,
): FenceFormikValues['parameters'] =>
  Object.entries(spec.parameters).reduce<FenceFormikValues['parameters']>(
    (previous, entry) => {
      const [id, parameter] = entry;

      const { content_type: type } = parameter;

      const str = existing?.fenceParameters[id] ?? parameter.default ?? '';

      let value: FenceParameter['value'];

      if (type === 'boolean') {
        value = ['1', 'on'].some((v) => v === str);
      } else {
        value = String(str);
      }

      previous[id] = {
        value,
      };

      return previous;
    },
    {},
  );

const buildFormikInitialValues = (
  template: APIFenceTemplate,
  fence?: APIFenceOverview,
): FenceFormikValues => {
  const values: FenceFormikValues = {
    agent: null,
    name: '',
    parameters: {},
    uuid: '',
  };

  if (fence) {
    const { fenceAgent: agent, fenceName: name, fenceUUID: uuid } = fence;

    values.agent = agent;
    values.name = name;

    values.parameters = buildFormikFenceParameters(template[agent], fence);

    values.uuid = uuid;
  }

  return values;
};

const buildInputs = <Values extends FenceFormikValues>(
  formikUtils: FormikUtils<Values>,
  group: APIFenceSpecParameterList,
  required?: boolean,
) => {
  const parameters = Object.entries(group);

  return parameters.reduce<React.ReactNode[]>((previous, parameter) => {
    const [id, spec] = parameter;

    const { deprecated, replacement } = spec;

    if (Number(deprecated) || replacement) {
      return previous;
    }

    previous.push(
      <Grid item key={`${id}-parameter-input`} width="100%">
        <FenceParameterInput<Values>
          formikUtils={formikUtils}
          id={id}
          parameter={spec}
          required={required}
        />
      </Grid>,
    );

    return previous;
  }, []);
};

const FenceForm: React.FC<FenceFormProps> = (props) => {
  const { fence, fences, template, tools } = props;

  const edit = fence !== undefined;

  const operation = useMemo(() => {
    let capped: string;
    let method: 'post' | 'put';
    let url: string;
    let value: string;

    if (edit) {
      method = 'put';
      url = `/fence/${fence.fenceUUID}`;
      value = 'update';

      capped = capitalize(value);
    } else {
      method = 'post';
      url = `/fence`;
      value = 'add';

      capped = capitalize(value);
    }

    return {
      capped,
      method,
      url,
      value,
    };
  }, [edit, fence?.fenceUUID]);

  const agentOptions = useMemo(
    () => Object.keys(template).sort((a, b) => a.localeCompare(b)),
    [template],
  );

  const initialValues = useMemo<FenceFormikValues>(
    () => buildFormikInitialValues(template, fence),
    [fence, template],
  );

  const formikUtils = useFormikUtils<FenceFormikValues>({
    initialValues,
    onSubmit: (values, { setSubmitting }) => {
      const { name, parameters } = values;

      const agent = String(values.agent);

      const data: APIFenceRequestBody = {
        agent,
        name,
        parameters: Object.entries(parameters).reduce<Record<string, string>>(
          (previous, entry) => {
            const [id, { value }] = entry;

            const { [agent]: spec } = template;

            if (!spec) {
              return previous;
            }

            const { [id]: parameter } = spec.parameters;

            const str = convertFenceParameterToString(
              value,
              parameter.content_type,
            );

            if (!edit && !str) {
              return previous;
            }

            if (str === parameter.default) {
              return previous;
            }

            previous[id] = str;

            return previous;
          },
          {},
        ),
      };

      tools.confirm.prepare({
        actionProceedText: operation.capped,
        content: (
          <FormSummary
            entries={data}
            hasPassword
            getEntryLabel={({ cap, depth, key }) => (depth ? key : cap(key))}
          />
        ),
        onCancelAppend: () => setSubmitting(false),
        onProceedAppend: () => {
          tools.confirm.loading(true);

          api
            .request({
              data,
              method: operation.method,
              url: operation.url,
            })
            .then(() => {
              tools.confirm.finish('Success', {
                children: (
                  <>
                    {operation.capped}ed fence device {name}
                  </>
                ),
              });

              tools.add.open(false);
            })
            .catch((error) => {
              const emsg = handleAPIError(error);

              emsg.children = (
                <>
                  Failed to {operation.value} fence device. {emsg.children}
                </>
              );

              tools.confirm.finish('Error', emsg);

              setSubmitting(false);
            });
        },
        titleText: `${operation.capped} fence device with the following?`,
      });

      tools.confirm.open();
    },
    validationSchema: buildFenceSchema(fence?.fenceUUID, fences, template),
  });

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      agent: 'agent',
      name: 'name',
      parameters: 'parameters',
    }),
    [],
  );

  const parameterGroups = useMemo(() => {
    let agent: APIFenceSpec | undefined;

    if (formik.values.agent) {
      ({ [formik.values.agent]: agent } = template);
    }

    return groupFenceParameters(agent);
  }, [formik.values.agent, template]);

  const optionalInputs = useMemo(
    () => buildInputs(formikUtils, parameterGroups.optional),
    [formikUtils, parameterGroups.optional],
  );

  const requiredInputs = useMemo(
    () => buildInputs(formikUtils, parameterGroups.required, true),
    [formikUtils, parameterGroups.required],
  );

  return (
    <Grid
      component="form"
      container
      onSubmit={(event) => {
        event.preventDefault();

        formik.submitForm();
      }}
      rowSpacing="1em"
    >
      <Grid item width="100%">
        <Grid container maxHeight="50vh" overflow="scroll" rowSpacing="1em">
          <Grid item width="100%">
            <Autocomplete
              disabled={edit}
              id={chains.agent}
              label="Fence device type"
              noOptionsText="No matching fence device type"
              onChange={(event, value) => {
                const clone: FenceFormikValues = {
                  ...formik.values,
                  agent: value,
                };

                if (value) {
                  const { [value]: spec } = template;

                  clone.parameters = buildFormikFenceParameters(spec, fence);
                }

                formik.setValues(clone, true);
              }}
              openOnFocus
              options={agentOptions}
              renderOption={(optionProps, id) => {
                const { [id]: agent } = template;

                const description =
                  typeof agent.description === 'string'
                    ? agent.description
                    : 'None';

                return (
                  <li {...optionProps} key={`fence-agent-${id}`}>
                    <Box>
                      <BodyText inheritColour>{id}</BodyText>
                      <BodyText selected={false}>{description}</BodyText>
                    </Box>
                  </li>
                );
              }}
              required
              value={formik.values.agent}
            />
          </Grid>
          {formik.values.agent && (
            <>
              <Grid item width="100%">
                <ExpandablePanel
                  expandInitially
                  header="Required parameters"
                  panelProps={{ mv: 0 }}
                >
                  <Grid container rowSpacing="0.6em">
                    <Grid item width="100%">
                      <UncontrolledInput
                        input={
                          <OutlinedInputWithLabel
                            id={chains.name}
                            label="Fence device name"
                            name={chains.name}
                            onChange={handleChange}
                            required
                            value={formik.values.name}
                          />
                        }
                      />
                    </Grid>
                    {requiredInputs}
                  </Grid>
                </ExpandablePanel>
              </Grid>
              <Grid item width="100%">
                <ExpandablePanel
                  header="Optional parameters"
                  panelProps={{
                    mv: 0,
                  }}
                >
                  <Grid container rowSpacing="0.6em">
                    {optionalInputs}
                  </Grid>
                </ExpandablePanel>
              </Grid>
            </>
          )}
        </Grid>
      </Grid>
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ActionGroup
          actions={[
            {
              background: 'blue',
              children: operation.capped,
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default FenceForm;
