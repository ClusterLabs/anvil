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

const EditFenceDeviceInputGroup: FC<EditFenceDeviceInputGroupProps> = ({
  fenceDeviceId,
  fenceDeviceTemplate,
}) => {
  const fenceParameterElements = useMemo(() => {
    let result: ReactNode;

    if (fenceDeviceTemplate && fenceDeviceId) {
      const { parameters: fenceDeviceParameters } =
        fenceDeviceTemplate[fenceDeviceId];

      const { optional: optionalInputs, required: requiredInputs } =
        Object.entries(fenceDeviceParameters).reduce<{
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

            const fenceJoinParameterId = `${fenceDeviceId}-${parameterId}`;
            const parameterIsRequired = isRequired === '1';
            const parameterInput = buildInput({
              id: fenceJoinParameterId,
              isChecked: CHECKED_STATES.includes(parameterDefault),
              isRequired: parameterIsRequired,
              label: parameterId,
              selectOptions: parameterSelectOptions,
              value: parameterDefault,
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
                id: `${fenceDeviceId}-name`,
                isRequired: true,
                label: 'Fence device name',
              }),
            ],
          },
        );

      result = (
        <>
          <ExpandablePanel expandInitially header="Required parameters">
            <FlexBox margin=".4em 0">{requiredInputs}</FlexBox>
          </ExpandablePanel>
          <ExpandablePanel header="Optional parameters">
            <FlexBox margin=".4em 0">{optionalInputs}</FlexBox>
          </ExpandablePanel>
        </>
      );
    }

    return result;
  }, [fenceDeviceId, fenceDeviceTemplate]);

  return <>{fenceParameterElements}</>;
};

export default EditFenceDeviceInputGroup;
