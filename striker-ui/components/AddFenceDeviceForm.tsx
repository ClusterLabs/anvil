import { Box } from '@mui/material';
import { FC, useMemo, useState } from 'react';
import useIsFirstRender from '../hooks/useIsFirstRender';
import useProtectedState from '../hooks/useProtectedState';
import api from '../lib/api';
import handleAPIError from '../lib/handleAPIError';
import Autocomplete from './Autocomplete';
import FlexBox from './FlexBox';
import Spinner from './Spinner';
import { BodyText } from './Text';

type FenceDeviceAutocompleteOption = {
  fenceDeviceDescription: string;
  fenceDeviceId: string;
  label: string;
};

const AddFenceDeivceForm: FC = () => {
  const isFirstRender = useIsFirstRender();

  const [fenceDeviceTemplate, setFenceDeviceTemplate] = useProtectedState<
    APIFenceTemplate | undefined
  >(undefined);
  const [inputFenceDeviceTypeValue, setInputFenceDeviceTypeValue] =
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

  const autocompleteFenceDeviceType = useMemo(
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
        value={inputFenceDeviceTypeValue}
      />
    ),
    [fenceDeviceTypeOptions, inputFenceDeviceTypeValue],
  );

  const formContent = useMemo(
    () =>
      isLoadingTemplate ? (
        <Spinner mt={0} />
      ) : (
        <>{autocompleteFenceDeviceType}</>
      ),
    [autocompleteFenceDeviceType, isLoadingTemplate],
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

  return <FlexBox>{formContent}</FlexBox>;
};

export default AddFenceDeivceForm;
