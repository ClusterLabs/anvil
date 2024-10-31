import { Grid } from '@mui/material';
import {
  DataSizeUnit,
  dSize,
  dSizeStr,
  FormatDataSizeOptions,
} from 'format-data-size';
import { FC, useMemo } from 'react';

import { DSIZE_SELECT_ITEMS } from '../../lib/consts/DSIZES';

import { toAnvilMemoryCalcable } from '../../lib/api_converters';
import { MemoryBar } from '../Bars';
import MessageGroup from '../MessageGroup';
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import { buildMemorySchema } from './schemas';
import ServerFormSubmit from './ServerFormSubmit';
import ServerFormGrid from './ServerFormGrid';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFetch from '../../hooks/useFetch';
import useFormikUtils from '../../hooks/useFormikUtils';

const BaseServerMemoryForm: FC<BaseServerMemoryFormProps> = (props) => {
  const { detail, memory } = props;

  const formikUtils = useFormikUtils<ServerMemoryFormikValues>({
    initialValues: {
      size:
        dSize(detail.memory.size, {
          fromUnit: 'B',
          toUnit: 'GiB',
        })?.value ?? '0',
      unit: 'GiB',
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: buildMemorySchema(memory),
  });
  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      size: `size`,
      unit: `unit`,
    }),
    [],
  );

  const formattedMemory = useMemo(() => {
    const options: FormatDataSizeOptions = {
      fromUnit: 'B',
      toUnit: formik.values.unit,
    };

    const allocated = dSizeStr(memory.allocated, options) ?? '';
    const available = dSizeStr(memory.available, options) ?? '';
    const reserved = dSizeStr(memory.reserved, options) ?? '';
    const total = dSizeStr(memory.total, options) ?? '';

    return {
      allocated,
      available,
      reserved,
      total,
    };
  }, [
    formik.values.unit,
    memory.allocated,
    memory.available,
    memory.reserved,
    memory.total,
  ]);

  return (
    <ServerFormGrid<ServerMemoryFormikValues> formik={formik}>
      <Grid item width="100%">
        <MemoryBar memory={memory} />
        <Grid container>
          <Grid item width="25%">
            <BodyText>Allocated: {formattedMemory.allocated}</BodyText>
            <BodyText>Reserved: {formattedMemory.reserved}</BodyText>
          </Grid>
          <Grid item width="50%" textAlign="center">
            <BodyText fontWeight={400}>
              Available: {formattedMemory.available}
            </BodyText>
          </Grid>
          <Grid item width="25%" textAlign="right">
            <BodyText>Total: {formattedMemory.total}</BodyText>
          </Grid>
        </Grid>
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedLabeledInputWithSelect
              id="server-memory-input"
              label="Memory"
              inputWithLabelProps={{
                id: chains.size,
                name: chains.size,
              }}
              onChange={handleChange}
              selectItems={DSIZE_SELECT_ITEMS}
              selectWithLabelProps={{
                id: chains.unit,
                name: chains.unit,
                onChange: (event) => {
                  const newUnit = event.target.value as DataSizeUnit;

                  const { size, unit } = formik.values;

                  const newDataSize = dSize(size, {
                    fromUnit: unit,
                    toUnit: newUnit,
                  });

                  if (!newDataSize) return;

                  const { value: newSize } = newDataSize;

                  formik.setValues({ size: newSize, unit: newUnit }, true);
                },
                value: formik.values.unit,
              }}
              value={formik.values.size}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ServerFormSubmit
          detail={detail}
          formDisabled={disabledSubmit}
          label="Save"
        />
      </Grid>
    </ServerFormGrid>
  );
};

const ServerMemoryForm: FC<ServerMemoryFormProps> = (props) => {
  const { detail } = props;

  const { altData: memory } = useFetch<AnvilMemory, AnvilMemoryCalcable>(
    `/anvil/${detail.anvil.uuid}/memory`,
    {
      mod: toAnvilMemoryCalcable,
      refreshInterval: 5000,
    },
  );

  if (!memory) {
    return <Spinner mt={0} />;
  }

  return <BaseServerMemoryForm memory={memory} {...props} />;
};

export default ServerMemoryForm;
