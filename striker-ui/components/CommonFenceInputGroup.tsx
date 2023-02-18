import { FC, ReactElement, ReactNode, useMemo } from 'react';

import FlexBox from './FlexBox';
import InputWithRef from './InputWithRef';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { ExpandablePanel } from './Panels';
import SelectWithLabel from './SelectWithLabel';
import SwitchWithLabel from './SwitchWithLabel';

const CHECKED_STATES: Array<string | undefined> = ['1', 'on'];

const MAP_TO_INPUT_BUILDER: MapToInputBuilder = {
  boolean: ({ id, isChecked = false, label }) => (
    <InputWithRef
      key={`${id}-wrapper`}
      input={<SwitchWithLabel id={id} label={label} checked={isChecked} />}
      valueType="boolean"
    />
  ),
  select: ({ id, isRequired, label, selectOptions = [], value = '' }) => (
    <InputWithRef
      key={`${id}-wrapper`}
      input={
        <SelectWithLabel
          id={id}
          label={label}
          selectItems={selectOptions}
          value={value}
        />
      }
      required={isRequired}
    />
  ),
  string: ({ id, isRequired, label = '', value }) => (
    <InputWithRef
      key={`${id}-wrapper`}
      input={<OutlinedInputWithLabel id={id} label={label} value={value} />}
      required={isRequired}
    />
  ),
};

const combineIds = (...pieces: string[]) => pieces.join('-');

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
        Object.entries(fenceParameters).reduce<{
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
                options: parameterSelectOptions,
                required: isRequired,
              },
            ],
          ) => {
            const { optional, required } = previous;
            const buildInput =
              MAP_TO_INPUT_BUILDER[contentType] ?? MAP_TO_INPUT_BUILDER.string;

            const fenceJoinParameterId = combineIds(fenceId, parameterId);
            const initialValue =
              mapToPreviousFenceParameterValues[fenceJoinParameterId] ??
              parameterDefault;
            const parameterIsRequired = isRequired === '1';
            const parameterInput = buildInput({
              id: fenceJoinParameterId,
              isChecked: CHECKED_STATES.includes(initialValue),
              isRequired: parameterIsRequired,
              label: parameterId,
              selectOptions: parameterSelectOptions,
              value: initialValue,
            });

            if (parameterIsRequired) {
              required.push(parameterInput);
            } else {
              optional.push(parameterInput);
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

export default CommonFenceInputGroup;
