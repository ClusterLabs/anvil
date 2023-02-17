import { Box } from '@mui/material';
import { FC, useMemo, useState } from 'react';

import api from '../lib/api';
import Autocomplete from './Autocomplete';
import ContainedButton from './ContainedButton';
import EditFenceDeviceInputGroup from './EditFenceDeviceInputGroup';
import FlexBox from './FlexBox';
import handleAPIError from '../lib/handleAPIError';
import Spinner from './Spinner';
import { BodyText } from './Text';
import useIsFirstRender from '../hooks/useIsFirstRender';
import useProtectedState from '../hooks/useProtectedState';

type FenceDeviceAutocompleteOption = {
  fenceDeviceDescription: string;
  fenceDeviceId: string;
  label: string;
};

const AddFenceDeviceForm: FC = () => {
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
  const fenceParameterElements = useMemo(
    () => (
      <EditFenceDeviceInputGroup
        fenceDeviceId={fenceDeviceTypeValue?.fenceDeviceId}
        fenceDeviceTemplate={fenceDeviceTemplate}
      />
    ),
    [fenceDeviceTemplate, fenceDeviceTypeValue],
  );

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

export default AddFenceDeviceForm;
