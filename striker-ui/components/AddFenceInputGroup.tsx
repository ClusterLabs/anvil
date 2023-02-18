import { Box } from '@mui/material';
import { FC, useMemo, useState } from 'react';

import api from '../lib/api';
import Autocomplete from './Autocomplete';
import CommonFenceInputGroup from './CommonFenceInputGroup';
import FlexBox from './FlexBox';
import handleAPIError from '../lib/handleAPIError';
import Spinner from './Spinner';
import { BodyText } from './Text';
import useIsFirstRender from '../hooks/useIsFirstRender';
import useProtectedState from '../hooks/useProtectedState';

type FenceAutocompleteOption = {
  fenceDescription: string;
  fenceId: string;
  label: string;
};

const AddFenceInputGroup: FC = () => {
  const isFirstRender = useIsFirstRender();

  const [fenceTemplate, setFenceTemplate] = useProtectedState<
    APIFenceTemplate | undefined
  >(undefined);
  const [fenceTypeValue, setInputFenceTypeValue] =
    useState<FenceAutocompleteOption | null>(null);
  const [isLoadingTemplate, setIsLoadingTemplate] =
    useProtectedState<boolean>(true);

  const fenceTypeOptions = useMemo<FenceAutocompleteOption[]>(
    () =>
      fenceTemplate
        ? Object.entries(fenceTemplate).map(
            ([id, { description: rawDescription }]) => {
              const description =
                typeof rawDescription === 'string'
                  ? rawDescription
                  : 'No description.';

              return {
                fenceDescription: description,
                fenceId: id,
                label: id,
              };
            },
          )
        : [],
    [fenceTemplate],
  );

  const fenceTypeElement = useMemo(
    () => (
      <Autocomplete
        id="add-fence-select-type"
        isOptionEqualToValue={(option, value) =>
          option.fenceId === value.fenceId
        }
        label="Fence device type"
        onChange={(event, newFenceType) => {
          setInputFenceTypeValue(newFenceType);
        }}
        openOnFocus
        options={fenceTypeOptions}
        renderOption={(props, { fenceDescription, fenceId }, { selected }) => (
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
              {fenceId}
            </BodyText>
            <BodyText selected={false}>{fenceDescription}</BodyText>
          </Box>
        )}
        value={fenceTypeValue}
      />
    ),
    [fenceTypeOptions, fenceTypeValue],
  );
  const fenceParameterElements = useMemo(
    () => (
      <CommonFenceInputGroup
        fenceId={fenceTypeValue?.fenceId}
        fenceTemplate={fenceTemplate}
      />
    ),
    [fenceTemplate, fenceTypeValue],
  );

  const formContent = useMemo(
    () =>
      isLoadingTemplate ? (
        <Spinner mt={0} />
      ) : (
        <FlexBox sx={{ '& > div': { marginBottom: 0 } }}>
          {fenceTypeElement}
          {fenceParameterElements}
        </FlexBox>
      ),
    [fenceTypeElement, fenceParameterElements, isLoadingTemplate],
  );

  if (isFirstRender) {
    api
      .get<APIFenceTemplate>(`/fence/template`)
      .then(({ data }) => {
        setFenceTemplate(data);
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

export default AddFenceInputGroup;
