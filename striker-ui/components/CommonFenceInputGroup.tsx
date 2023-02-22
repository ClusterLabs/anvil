import { FC, ReactElement, ReactNode, useMemo } from 'react';

import FlexBox from './FlexBox';
import InputWithRef from './InputWithRef';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { ExpandablePanel } from './Panels';
import SelectWithLabel from './SelectWithLabel';
import SwitchWithLabel from './SwitchWithLabel';

const CHECKED_STATES: Array<string | undefined> = ['1', 'on'];
const ID_SEPARATOR = '-';

const MAP_TO_INPUT_BUILDER: MapToInputBuilder = {
  boolean: ({ id, isChecked = false, label, name = id }) => (
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
  ),
  select: ({
    id,
    isRequired,
    label,
    name = id,
    selectOptions = [],
    value = '',
  }) => (
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
  ),
  string: ({ id, isRequired, label = '', name = id, value }) => (
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
      required={isRequired}
    />
  ),
};

const combineIds = (...pieces: string[]) => pieces.join(ID_SEPARATOR);

const CommonFenceInputGroup: FC<CommonFenceInputGroupProps> = ({
  fenceId,
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
                  content_type: contentType,
                  default: parameterDefault,
                  deprecated: rawDeprecated,
                  options: parameterSelectOptions,
                  required: rawRequired,
                },
              ],
            ) => {
              const isParameterDeprecated = String(rawDeprecated) === '1';

              if (!isParameterDeprecated) {
                const { optional, required } = previous;
                const buildInput =
                  MAP_TO_INPUT_BUILDER[contentType] ??
                  MAP_TO_INPUT_BUILDER.string;
                const fenceJoinParameterId = combineIds(fenceId, parameterId);

                const initialValue =
                  mapToPreviousFenceParameterValues[fenceJoinParameterId] ??
                  parameterDefault;
                const isParameterRequired = String(rawRequired) === '1';

                const parameterInput = buildInput({
                  id: fenceJoinParameterId,
                  isChecked: CHECKED_STATES.includes(initialValue),
                  isRequired: isParameterRequired,
                  label: parameterId,
                  selectOptions: parameterSelectOptions,
                  value: initialValue,
                });

                if (isParameterRequired) {
                  required.push(parameterInput);
                } else {
                  optional.push(parameterInput);
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
            <FlexBox margin=".4em 0">{requiredInputs}</FlexBox>
          </ExpandablePanel>
          <ExpandablePanel header="Optional parameters">
            <FlexBox margin=".4em 0">{optionalInputs}</FlexBox>
          </ExpandablePanel>
        </FlexBox>
      );
    }

    return result;
  }, [fenceId, fenceTemplate, previousFenceName, previousFenceParameters]);

  return <>{fenceParameterElements}</>;
};

export { ID_SEPARATOR };

export default CommonFenceInputGroup;
