import { Box as MuiBox, Tooltip as MuiTooltip } from '@mui/material';
import { useMemo } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';
import { REP_LABEL_PASSW } from '../../lib/consts/REG_EXP_PATTERNS';

import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import SelectWithLabel from '../SelectWithLabel';
import SwitchWithLabel from '../SwitchWithLabel';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';

type FenceParameterInputOptionalProps = {
  required?: boolean;
};

type FenceParameterInputProps<Values extends FenceFormikValues> =
  FenceParameterInputOptionalProps & {
    formikUtils: FormikUtils<Values>;
    id: string;
    parameter: APIFenceSpecParameter;
  };

const FenceParameterInput = <Values extends FenceFormikValues>(
  ...[props]: Parameters<React.FC<FenceParameterInputProps<Values>>>
): ReturnType<React.FC<FenceParameterInputProps<Values>>> => {
  const { formikUtils, id, parameter, required } = props;

  const {
    content_type: parameterType,
    default: parameterDefault,
    description,
    options = [],
  } = parameter;

  const { changeFieldValue, formik, handleChange } = formikUtils;

  const chain = `parameters.${id}.value`;

  const input = useMemo<React.ReactElement>(() => {
    if (parameterType === 'boolean') {
      const checked = Boolean(formik.values.parameters[id].value);

      return (
        <SwitchWithLabel
          checked={checked}
          id={chain}
          label={id}
          name={chain}
          onChange={(event, changed) => {
            changeFieldValue(chain, changed, true);
          }}
        />
      );
    }

    const value = String(formik.values.parameters[id].value);

    if (parameterType === 'select') {
      return (
        <SelectWithLabel
          id={chain}
          label={id}
          name={chain}
          onChange={formik.handleChange}
          required={required}
          selectItems={options}
          selectProps={{
            onClearIndicatorClick: () => {
              changeFieldValue(chain, '', true);
            },
          }}
          value={value}
        />
      );
    }

    let inputType: string | undefined;

    if (REP_LABEL_PASSW.test(id)) {
      inputType = INPUT_TYPES.password;
    } else if (parameterType !== 'string') {
      inputType = INPUT_TYPES.number;
    }

    return (
      <UncontrolledInput
        input={
          <OutlinedInputWithLabel
            disableAutofill
            id={chain}
            inputProps={{
              placeholder: parameterDefault,
            }}
            label={id}
            name={chain}
            onChange={handleChange}
            required={required}
            type={inputType}
            value={value}
          />
        }
      />
    );
  }, [
    chain,
    changeFieldValue,
    formik,
    handleChange,
    id,
    options,
    parameterDefault,
    parameterType,
    required,
  ]);

  const tooltip = useMemo(
    () => (
      <MuiTooltip
        disableInteractive
        key={`${id}-tooltip`}
        placement="top-start"
        slotProps={{
          tooltip: {
            sx: {
              maxWidth: {
                md: '63em',
              },
            },
          },
        }}
        title={<BodyText>{description}</BodyText>}
      >
        <MuiBox>{input}</MuiBox>
      </MuiTooltip>
    ),
    [description, id, input],
  );

  return tooltip;
};

export default FenceParameterInput;
