import { Box, styled, Tooltip } from '@mui/material';
import { ReactElement, ReactNode, useMemo } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';
import { REP_LABEL_PASSW } from '../../lib/consts/REG_EXP_PATTERNS';

import FlexBox from '../FlexBox';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { ExpandablePanel } from '../Panels';
import SelectWithLabel from '../SelectWithLabel';
import SwitchWithLabel from '../SwitchWithLabel';
import {
  buildIPAddressTestBatch,
  buildNumberTestBatch,
  buildPeacefulStringTestBatch,
  testNotBlank,
} from '../../lib/test_input';
import { BodyText } from '../Text';

const CHECKED_STATES: Array<string | undefined> = ['1', 'on'];

const INPUT_ID_SEPARATOR = '-';

const getStringParamInputTestBatch = <M extends MapToInputTestID>({
  formUtils: { buildFinishInputTestBatchFunction, setMessage },
  id,
  label,
}: {
  formUtils: FormUtils<M>;
  id: string;
  label: string;
}) => {
  const onFinishBatch = buildFinishInputTestBatchFunction(id);

  const onSuccess = () => {
    setMessage(id);
  };

  return label.toLowerCase() === 'ip'
    ? buildIPAddressTestBatch(
        label,
        onSuccess,
        { onFinishBatch },
        (message) => {
          setMessage(id, { children: message });
        },
      )
    : {
        defaults: {
          onSuccess,
        },
        onFinishBatch,
        tests: [{ test: testNotBlank }],
      };
};

const buildNumberParamInput = <M extends MapToInputTestID>(
  args: FenceParameterInputBuilderParameters<M>,
): ReactElement => {
  const { formUtils, id, isRequired, label = '', name = id, value } = args;

  const {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    setMessage,
  } = formUtils;

  return (
    <InputWithRef
      key={`${id}-wrapper`}
      input={
        <OutlinedInputWithLabel
          id={id}
          label={label}
          name={name}
          value={value}
        />
      }
      inputTestBatch={buildNumberTestBatch(
        label,
        () => {
          setMessage(id);
        },
        { onFinishBatch: buildFinishInputTestBatchFunction(id) },
        (message) => {
          setMessage(id, { children: message });
        },
      )}
      onFirstRender={buildInputFirstRenderFunction(id)}
      required={isRequired}
      valueType="number"
    />
  );
};

const MAP_TO_INPUT_BUILDER: MapToInputBuilder<Record<string, string>> = {
  boolean: (args) => {
    const { id, isChecked = false, label, name = id } = args;

    return (
      <InputWithRef
        key={`${id}-wrapper`}
        input={
          <SwitchWithLabel
            checked={isChecked}
            id={id}
            label={label}
            name={name}
          />
        }
        valueType="boolean"
      />
    );
  },
  integer: buildNumberParamInput,
  second: buildNumberParamInput,
  select: (args) => {
    const {
      formUtils,
      id,
      isRequired,
      label,
      name = id,
      selectOptions = [],
      value = '',
    } = args;

    const {
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      setMessage,
    } = formUtils;

    return (
      <InputWithRef
        key={`${id}-wrapper`}
        input={
          <SelectWithLabel
            id={id}
            label={label}
            name={name}
            selectItems={selectOptions}
            value={value}
          />
        }
        inputTestBatch={{
          defaults: {
            onSuccess: () => {
              setMessage(id);
            },
          },
          onFinishBatch: buildFinishInputTestBatchFunction(id),
          tests: [{ test: testNotBlank }],
        }}
        onFirstRender={buildInputFirstRenderFunction(id)}
        required={isRequired}
      />
    );
  },
  string: (args) => {
    const {
      formUtils,
      id,
      isRequired,
      isSensitive = false,
      label = '',
      name = id,
      value,
    } = args;

    const { buildInputFirstRenderFunction } = formUtils;

    let inputType;

    if (isSensitive) {
      inputType = INPUT_TYPES.password;
    }

    return (
      <InputWithRef
        key={`${id}-wrapper`}
        input={
          <OutlinedInputWithLabel
            id={id}
            label={label}
            name={name}
            type={inputType}
            value={value}
          />
        }
        inputTestBatch={getStringParamInputTestBatch({ formUtils, id, label })}
        onFirstRender={buildInputFirstRenderFunction(id)}
        required={isRequired}
      />
    );
  },
};

const combineIds = (...pieces: string[]) => pieces.join(INPUT_ID_SEPARATOR);

const FenceInputWrapper = styled(FlexBox)({
  margin: '.4em 0',
});

const CommonFenceInputGroup = <M extends Record<string, string>>({
  fenceId,
  fenceParameterTooltipProps,
  fenceTemplate,
  formUtils,
  previousFenceName,
  previousFenceParameters,
}: CommonFenceInputGroupProps<M>): ReactElement => {
  const {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    setMessage,
  } = formUtils;

  const fenceParameterElements = useMemo(() => {
    let result: ReactNode;

    if (fenceTemplate && fenceId) {
      const { parameters: fenceParameters } = fenceTemplate[fenceId];

      let mapToPreviousFenceParameterValues: FenceParameters = {};

      if (previousFenceParameters) {
        mapToPreviousFenceParameterValues = Object.entries(
          previousFenceParameters,
        ).reduce<FenceParameters>((previous, [parameterId, parameterValue]) => {
          const newKey = combineIds(fenceId, parameterId);

          previous[newKey] = parameterValue;

          return previous;
        }, {});
      }

      const { optional: optionalInputs, required: requiredInputs } =
        Object.entries(fenceParameters)
          .sort(([a], [b]) => (a > b ? 1 : -1))
          .reduce<{
            optional: ReactElement[];
            required: ReactElement[];
          }>(
            (
              previous,
              [
                parameterId,
                {
                  content_type: parameterType,
                  default: parameterDefault,
                  deprecated: parameterDeprecated,
                  description: parameterDescription,
                  options: parameterSelectOptions,
                  replacement: parameterReplacement,
                  required: parameterRequired,
                },
              ],
            ) => {
              const isParameterDeprecated = Number(parameterDeprecated) === 1;

              if (
                [isParameterDeprecated, parameterReplacement].some((v) => v)
              ) {
                return previous;
              }

              const { optional, required } = previous;
              const buildInput =
                MAP_TO_INPUT_BUILDER[parameterType] ??
                MAP_TO_INPUT_BUILDER.string;
              const fenceJoinParameterId = combineIds(fenceId, parameterId);

              const initialValue =
                mapToPreviousFenceParameterValues[fenceJoinParameterId] ??
                parameterDefault;
              const isParameterRequired = /plug|port/i.test(parameterId)
                ? false
                : Number(parameterRequired) === 1;
              const isParameterSensitive = REP_LABEL_PASSW.test(parameterId);

              const parameterInput = buildInput({
                formUtils,
                id: fenceJoinParameterId,
                isChecked: CHECKED_STATES.includes(initialValue),
                isRequired: isParameterRequired,
                isSensitive: isParameterSensitive,
                label: parameterId,
                selectOptions: parameterSelectOptions,
                value: initialValue,
              });
              const parameterInputWithTooltip = (
                <Tooltip
                  componentsProps={{
                    tooltip: {
                      sx: {
                        maxWidth: { md: '62.6em' },
                      },
                    },
                  }}
                  disableInteractive
                  key={`${fenceJoinParameterId}-tooltip`}
                  placement="top-start"
                  title={<BodyText>{parameterDescription}</BodyText>}
                  {...fenceParameterTooltipProps}
                >
                  <Box>{parameterInput}</Box>
                </Tooltip>
              );

              if (isParameterRequired) {
                required.push(parameterInputWithTooltip);
              } else {
                optional.push(parameterInputWithTooltip);
              }

              return previous;
            },
            {
              optional: [],
              required: [],
            },
          );

      const inputIdFenceName = combineIds(fenceId, 'name');
      const inputLabelFenceName = 'Fence device name';

      result = (
        <FlexBox
          sx={{
            '& > div:first-child': { marginTop: 0 },
            '& > div': { marginBottom: 0 },
          }}
        >
          <ExpandablePanel expandInitially header="Required parameters">
            <FenceInputWrapper>
              <InputWithRef
                key={`${inputIdFenceName}-wrapper`}
                input={
                  <OutlinedInputWithLabel
                    disableAutofill
                    id={inputIdFenceName}
                    label={inputLabelFenceName}
                    name={inputIdFenceName}
                    value={previousFenceName}
                  />
                }
                inputTestBatch={buildPeacefulStringTestBatch(
                  inputLabelFenceName,
                  () => {
                    setMessage(inputIdFenceName);
                  },
                  {
                    onFinishBatch:
                      buildFinishInputTestBatchFunction(inputIdFenceName),
                  },
                  (message) => {
                    setMessage(inputIdFenceName, { children: message });
                  },
                )}
                onFirstRender={buildInputFirstRenderFunction(inputIdFenceName)}
                required
              />
              {requiredInputs}
            </FenceInputWrapper>
          </ExpandablePanel>
          <ExpandablePanel header="Optional parameters">
            <FenceInputWrapper>{optionalInputs}</FenceInputWrapper>
          </ExpandablePanel>
        </FlexBox>
      );
    }

    return result;
  }, [
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    fenceId,
    fenceParameterTooltipProps,
    fenceTemplate,
    formUtils,
    previousFenceName,
    previousFenceParameters,
    setMessage,
  ]);

  return <>{fenceParameterElements}</>;
};

export { INPUT_ID_SEPARATOR };

export default CommonFenceInputGroup;
