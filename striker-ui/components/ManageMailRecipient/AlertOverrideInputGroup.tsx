import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import Autocomplete from '../Autocomplete';
import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import SelectWithLabel from '../SelectWithLabel';
import { BodyText, SmallText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';

const LEVEL_OPTIONS: SelectItem<number>[] = [
  { displayValue: 'Critical', value: 1 },
  { displayValue: 'Warning', value: 2 },
  { displayValue: 'Notice', value: 3 },
  { displayValue: 'Info', value: 4 },
];

const AlertOverrideInputGroup: FC<AlertOverrideInputGroupProps> = (props) => {
  const {
    alertOverrideTargetOptions,
    alertOverrideUuid,
    mailRecipientUuid: mrUuid,
    formikUtils,
  } = props;

  const aoUuid = useMemo<string>(
    () => alertOverrideUuid ?? uuidv4(),
    [alertOverrideUuid],
  );

  const { formik } = formikUtils;
  const {
    values: { [mrUuid]: mailRecipient },
  } = formik;
  const {
    alertOverrides: { [aoUuid]: alertOverride },
  } = mailRecipient;

  const overrideChain = useMemo<string>(
    () => `${mrUuid}.alertOverrides.${aoUuid}`,
    [aoUuid, mrUuid],
  );
  const targetChain = useMemo<string>(
    () => `${overrideChain}.target`,
    [overrideChain],
  );
  const levelChain = useMemo<string>(
    () => `${overrideChain}.level`,
    [overrideChain],
  );

  return (
    <Grid
      alignItems="center"
      columns={{ xs: 1, sm: 10 }}
      container
      justifyContent="stretch"
      spacing="1em"
    >
      <Grid item xs={6}>
        <Autocomplete
          getOptionLabel={(option) => option.name}
          id={targetChain}
          isOptionEqualToValue={(option, value) => option.uuid === value.uuid}
          label="Target"
          noOptionsText="No node or subnode found."
          onChange={(event, value) =>
            formik.setFieldValue(targetChain, value, true)
          }
          openOnFocus
          options={alertOverrideTargetOptions}
          renderOption={(optionProps, option) => (
            <li {...optionProps} key={`${option.node}-${option.uuid}`}>
              {option.type === 'node' ? (
                <FlexBox spacing={0}>
                  <BodyText inheritColour>{option.name}</BodyText>
                  <SmallText inheritColour>{option.description}</SmallText>
                </FlexBox>
              ) : (
                <BodyText inheritColour paddingLeft=".6em">
                  {option.name}
                </BodyText>
              )}
            </li>
          )}
          value={alertOverride.target}
        />
      </Grid>
      <Grid item flexGrow={1}>
        <UncontrolledInput
          input={
            <SelectWithLabel
              id={levelChain}
              label="Alert level"
              name={levelChain}
              onChange={formik.handleChange}
              selectItems={LEVEL_OPTIONS}
              value={alertOverride.level}
            />
          }
        />
      </Grid>
      <Grid item width="min-content">
        <IconButton
          mapPreset="delete"
          onClick={() => {
            formik.setFieldValue(overrideChain, undefined, true);
          }}
          size="small"
        />
      </Grid>
    </Grid>
  );
};

export default AlertOverrideInputGroup;
