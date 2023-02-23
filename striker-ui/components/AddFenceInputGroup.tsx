import { Box } from '@mui/material';
import { FC, useMemo, useState } from 'react';

import Autocomplete from './Autocomplete';
import CommonFenceInputGroup from './CommonFenceInputGroup';
import FlexBox from './FlexBox';
import Spinner from './Spinner';
import { BodyText } from './Text';

const AddFenceInputGroup: FC<AddFenceInputGroupProps> = ({
  fenceTemplate: externalFenceTemplate,
  loading: isExternalLoading,
}) => {
  const [fenceTypeValue, setInputFenceTypeValue] =
    useState<FenceAutocompleteOption | null>(null);

  const fenceTypeOptions = useMemo<FenceAutocompleteOption[]>(
    () =>
      externalFenceTemplate
        ? Object.entries(externalFenceTemplate)
            .sort(([a], [b]) => (a > b ? 1 : -1))
            .map(([id, { description: rawDescription }]) => {
              const description =
                typeof rawDescription === 'string'
                  ? rawDescription
                  : 'No description.';

              return {
                fenceDescription: description,
                fenceId: id,
                label: id,
              };
            })
        : [],
    [externalFenceTemplate],
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
        sx={{ marginTop: '.3em' }}
        value={fenceTypeValue}
      />
    ),
    [fenceTypeOptions, fenceTypeValue],
  );
  const fenceParameterElements = useMemo(
    () => (
      <CommonFenceInputGroup
        fenceId={fenceTypeValue?.fenceId}
        fenceTemplate={externalFenceTemplate}
      />
    ),
    [externalFenceTemplate, fenceTypeValue],
  );

  const content = useMemo(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <FlexBox>
          {fenceTypeElement}
          {fenceParameterElements}
        </FlexBox>
      ),
    [fenceTypeElement, fenceParameterElements, isExternalLoading],
  );

  return <>{content}</>;
};

export default AddFenceInputGroup;
