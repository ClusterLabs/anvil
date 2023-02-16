import { Box, Switch } from '@mui/material';
import { FC, ReactElement, ReactNode, useMemo, useState } from 'react';

import api from '../lib/api';
import Autocomplete from './Autocomplete';
import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import handleAPIError from '../lib/handleAPIError';
import InputWithRef from './InputWithRef';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { ExpandablePanel } from './Panels';
import SelectWithLabel from './SelectWithLabel';
import Spinner from './Spinner';
import { BodyText } from './Text';
import useIsFirstRender from '../hooks/useIsFirstRender';
import useProtectedState from '../hooks/useProtectedState';

type FenceDeviceAutocompleteOption = {
  fenceDeviceDescription: string;
  fenceDeviceId: string;
  label: string;
};

type FenceParameterInputBuilder = (args: {
  id: string;
  isChecked?: boolean;
  isRequired?: boolean;
  label?: string;
  selectOptions?: string[];
  value?: string;
}) => ReactElement;

const MAP_TO_INPUT_BUILDER: Partial<
  Record<Exclude<FenceParameterType, 'string'>, FenceParameterInputBuilder>
> & { string: FenceParameterInputBuilder } = {
  boolean: ({ id, isChecked = false, label }) => (
    <FlexBox key={`${id}-wrapper`} row>
      <BodyText flexGrow={1}>{label}</BodyText>
      <Switch checked={isChecked} edge="end" id={id} />
    </FlexBox>
  ),
  select: ({ id, isRequired, label, selectOptions = [], value = '' }) => (
    <InputWithRef
      key={`${id}-wrapper`}
      input={
        <SelectWithLabel
          id={id}
          label={label}
          selectItems={selectOptions}
          selectProps={{ value }}
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

const AddFenceDeivceForm: FC = () => {
  const isFirstRender = useIsFirstRender();

  const [fenceDeviceTemplate, setFenceDeviceTemplate] = useProtectedState<
    APIFenceTemplate | undefined
  >(undefined);
  const [fenceDeviceTypeValue, setInputFenceDeviceTypeValue] =
    useState<FenceDeviceAutocompleteOption | null>(null);
  const [isLoadingTemplate, setIsLoadingTemplate] =
    useProtectedState<boolean>(true);

  const fenceDeviceTypeOptions = useMemo<FenceDeviceAutocompleteOption[]>(
    () =>
      fenceDeviceTemplate
        ? Object.entries(fenceDeviceTemplate).map(
            ([id, { description: rawDescription }]) => {
              const description =
                typeof rawDescription === 'string'
                  ? rawDescription
                  : 'No description.';

              return {
                fenceDeviceDescription: description,
                fenceDeviceId: id,
                label: id,
              };
            },
          )
        : [],
    [fenceDeviceTemplate],
  );

  const fenceDeviceTypeElement = useMemo(
    () => (
      <Autocomplete
        id="add-fence-device-pick-type"
        isOptionEqualToValue={(option, value) =>
          option.fenceDeviceId === value.fenceDeviceId
        }
        label="Fence device type"
        onChange={(event, newFenceDeviceType) => {
          setInputFenceDeviceTypeValue(newFenceDeviceType);
        }}
        openOnFocus
        options={fenceDeviceTypeOptions}
        renderOption={(
          props,
          { fenceDeviceDescription, fenceDeviceId },
          { selected },
        ) => (
          <Box
            component="li"
            sx={{
              display: 'flex',
              flexDirection: 'column',

              '& > *': {
                width: '100%',
              },
            }}
            {...props}
          >
            <BodyText
              inverted
              sx={{
                fontSize: '1.2em',
                fontWeight: selected ? 400 : undefined,
              }}
            >
              {fenceDeviceId}
            </BodyText>
            <BodyText selected={false}>{fenceDeviceDescription}</BodyText>
          </Box>
        )}
        value={fenceDeviceTypeValue}
      />
    ),
    [fenceDeviceTypeOptions, fenceDeviceTypeValue],
  );
  const fenceParameterElements = useMemo(() => {
    let result: ReactNode;

    if (fenceDeviceTemplate && fenceDeviceTypeValue) {
      const { fenceDeviceId } = fenceDeviceTypeValue;
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
              isChecked: parameterDefault === '1',
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
  }, [fenceDeviceTemplate, fenceDeviceTypeValue]);

  const formContent = useMemo(
    () =>
      isLoadingTemplate ? (
        <Spinner mt={0} />
      ) : (
        <FlexBox
          component="form"
          onSubmit={(event) => {
            event.preventDefault();
          }}
          sx={{ '& > div': { marginBottom: 0 } }}
        >
          {fenceDeviceTypeElement}
          {fenceParameterElements}
          <FlexBox row justifyContent="flex-end">
            <ContainedButton type="submit">Add fence device</ContainedButton>
          </FlexBox>
        </FlexBox>
      ),
    [fenceDeviceTypeElement, fenceParameterElements, isLoadingTemplate],
  );

  if (isFirstRender) {
    api
      .get<APIFenceTemplate>(`/fence/template`)
      .then(({ data }) => {
        setFenceDeviceTemplate(data);
      })
      .catch((error) => {
        handleAPIError(error);
      })
      .finally(() => {
        setIsLoadingTemplate(false);
      });
  }

  return <>{formContent}</>;
};

export default AddFenceDeivceForm;
