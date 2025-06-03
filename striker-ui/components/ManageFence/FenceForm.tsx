import { Box, Grid } from '@mui/material';
import { useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import Autocomplete from '../Autocomplete';
import FenceParameterInput from './FenceParameterInput';
import groupFenceParameters from './groupFenceParameters';
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
};

const buildFormikInitialValues = (
  fence?: APIFenceOverview,
): FenceFormikValues => {
  const values: FenceFormikValues = {
    agent: null,
    name: '',
    parameters: {},
    uuid: '',
  };

  if (fence) {
    const {
      fenceAgent: agent,
      fenceName: name,
      fenceParameters: parameters,
      fenceUUID: uuid,
    } = fence;

    values.agent = agent;
    values.name = name;

    Object.entries(parameters).reduce<Record<string, FenceParameter>>(
      (previous, parameter) => {
        const [id, value] = parameter;

        previous[id] = {
          value,
        };

        return previous;
      },
      values.parameters,
    );

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
  const { fence, fences, template } = props;

  const edit = fence !== undefined;

  const agentOptions = useMemo(() => Object.keys(template), [template]);

  const formikUtils = useFormikUtils<FenceFormikValues>({
    initialValues: buildFormikInitialValues(fence),
    onSubmit: () => {},
    validationSchema: buildFenceSchema(fence?.fenceUUID, fences, agentOptions),
  });

  const {
    changeFieldValue,
    disabledSubmit,
    formik,
    formikErrors,
    handleChange,
  } = formikUtils;

  const chains = useMemo(
    () => ({
      agent: 'agent',
      name: 'name',
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
                changeFieldValue(chains.agent, value, true);
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
              children: edit ? 'Save' : 'Add',
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
