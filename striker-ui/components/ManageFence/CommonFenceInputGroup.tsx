import { Box, styled, Tooltip } from '@mui/material';
import { FC, ReactElement, ReactNode, useMemo } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import FlexBox from '../FlexBox';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { ExpandablePanel } from '../Panels';
import SelectWithLabel from '../SelectWithLabel';
import SwitchWithLabel from '../SwitchWithLabel';
import { BodyText } from '../Text';

const CHECKED_STATES: Array<string | undefined> = ['1', 'on'];
const ID_SEPARATOR = '-';

const MAP_TO_INPUT_BUILDER: MapToInputBuilder = {
  boolean: (args) => {
    const { id, isChecked = false, label, name = id } = args;

    return (
      <InputWithRef
        key={`${id}-wrapper`}
        input={
          <SwitchWithLabel
            checked={isChecked}
            flexBoxProps={{ width: '100%' }}
            id={id}
            label={label}
            name={name}
          />
        }
        valueType="boolean"
      />
    );
  },
  select: (args) => {
    const {
      id,
      isRequired,
      label,
      name = id,
      selectOptions = [],
      value = '',
    } = args;

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
        required={isRequired}
      />
    );
  },
  string: (args) => {
    const {
      id,
      isRequired,
      isSensitive = false,
      label = '',
      name = id,
      value,
    } = args;

    return (
      <InputWithRef
        key={`${id}-wrapper`}
        input={
          <OutlinedInputWithLabel
            id={id}
            inputProps={{
              inputProps: { 'data-sensitive': isSensitive },
            }}
            label={label}
            name={name}
            value={value}
            type={isSensitive ? INPUT_TYPES.password : undefined}
          />
        }
        required={isRequired}
      />
    );
  },
};

const combineIds = (...pieces: string[]) => pieces.join(ID_SEPARATOR);

const FenceInputWrapper = styled(FlexBox)({
  margin: '.4em 0',
});

const CommonFenceInputGroup: FC<CommonFenceInputGroupProps> = ({
  fenceId,
  fenceParameterTooltipProps,
  fenceTemplate,
  previousFenceName,
  previousFenceParameters,
}) => {
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
                  deprecated: rawParameterDeprecated,
                  description: parameterDescription,
                  options: parameterSelectOptions,
                  required: rawParameterRequired,
                },
              ],
            ) => {
              const isParameterDeprecated =
                String(rawParameterDeprecated) === '1';

              if (!isParameterDeprecated) {
                const { optional, required } = previous;
                const buildInput =
                  MAP_TO_INPUT_BUILDER[parameterType] ??
                  MAP_TO_INPUT_BUILDER.string;
                const fenceJoinParameterId = combineIds(fenceId, parameterId);

                const initialValue =
                  mapToPreviousFenceParameterValues[fenceJoinParameterId] ??
                  parameterDefault;
                const isParameterRequired =
                  String(rawParameterRequired) === '1';
                const isParameterSensitive = /passw/i.test(parameterId);

                const parameterInput = buildInput({
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
              }

              return previous;
            },
            {
              optional: [],
              required: [
                MAP_TO_INPUT_BUILDER.string({
                  id: combineIds(fenceId, 'name'),
                  isRequired: true,
                  label: 'Fence device name',
                  value: previousFenceName,
                }),
              ],
            },
          );

      result = (
        <FlexBox
          sx={{
            '& > div:first-child': { marginTop: 0 },
            '& > div': { marginBottom: 0 },
          }}
        >
          <ExpandablePanel expandInitially header="Required parameters">
            <FenceInputWrapper>{requiredInputs}</FenceInputWrapper>
          </ExpandablePanel>
          <ExpandablePanel header="Optional parameters">
            <FenceInputWrapper>{optionalInputs}</FenceInputWrapper>
          </ExpandablePanel>
        </FlexBox>
      );
    }

    return result;
  }, [
    fenceId,
    fenceParameterTooltipProps,
    fenceTemplate,
    previousFenceName,
    previousFenceParameters,
  ]);

  return <>{fenceParameterElements}</>;
};

export { ID_SEPARATOR };

export default CommonFenceInputGroup;
