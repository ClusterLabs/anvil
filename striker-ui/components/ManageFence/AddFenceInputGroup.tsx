import { Box } from '@mui/material';
import { ReactElement, useEffect, useMemo, useState } from 'react';

import Autocomplete from '../Autocomplete';
import CommonFenceInputGroup from './CommonFenceInputGroup';
import FlexBox from '../FlexBox';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import useIsFirstRender from '../../hooks/useIsFirstRender';

const INPUT_ID_FENCE_AGENT = 'add-fence-input-agent';

const AddFenceInputGroup = <M extends Record<string, string>>({
  fenceTemplate: externalFenceTemplate,
  formUtils,
  loading: isExternalLoading,
}: AddFenceInputGroupProps<M>): ReactElement => {
  const { setValidity } = formUtils;

  const isFirstRender = useIsFirstRender();

  const [inputFenceTypeValue, setInputFenceTypeValue] =
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
        id={INPUT_ID_FENCE_AGENT}
        isOptionEqualToValue={(option, value) =>
          option.fenceId === value.fenceId
        }
        label="Fence device type"
        onChange={(event, newFenceType) => {
          setValidity(INPUT_ID_FENCE_AGENT, newFenceType !== null);
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
        value={inputFenceTypeValue}
      />
    ),
    [fenceTypeOptions, inputFenceTypeValue, setValidity],
  );

  const fenceParameterElements = useMemo(
    () => (
      <CommonFenceInputGroup
        fenceId={inputFenceTypeValue?.fenceId}
        fenceTemplate={externalFenceTemplate}
        formUtils={formUtils}
      />
    ),
    [externalFenceTemplate, inputFenceTypeValue?.fenceId, formUtils],
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

  useEffect(() => {
    if (isFirstRender) {
      setValidity(INPUT_ID_FENCE_AGENT, inputFenceTypeValue !== null);
    }
  }, [inputFenceTypeValue, isFirstRender, setValidity]);

  return <>{content}</>;
};

export { INPUT_ID_FENCE_AGENT };

export default AddFenceInputGroup;
