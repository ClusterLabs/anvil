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

const DEFAULT_UNIT: DataSizeUnit = 'GiB';

const BaseServerMemoryForm: FC<BaseServerMemoryFormProps> = (props) => {
  const { detail, memory } = props;

  const formikUtils = useFormikUtils<ServerMemoryFormikValues>({
    initialValues: {
      size: {
        unit: DEFAULT_UNIT,
        value:
          dSize(detail.memory.size, { toUnit: DEFAULT_UNIT })?.value ?? '0',
      },
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: buildMemorySchema(memory),
  });
  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(() => {
    const base = `size`;

    return {
      size: base,
      unit: `${base}.unit`,
      value: `${base}.value`,
    };
  }, []);

  const formattedMemory = useMemo(() => {
    const options: FormatDataSizeOptions = {
      toUnit: formik.values.size.unit,
    };

    const allocated = dSizeStr(memory.allocated, options);
    const available = dSizeStr(memory.available, options);
    const reserved = dSizeStr(memory.reserved, options);
    const total = dSizeStr(memory.total, options);

    return {
      allocated,
      available,
      reserved,
      total,
    };
  }, [
    formik.values.size.unit,
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
          <Grid item>
            <BodyText>Allocated: {formattedMemory.allocated}</BodyText>
          </Grid>
          <Grid item textAlign="center" xs>
            <BodyText fontWeight={400}>
              Available: {formattedMemory.available}
            </BodyText>
          </Grid>
          <Grid item textAlign="right">
            <BodyText>System reserved: {formattedMemory.reserved}</BodyText>
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
                id: chains.value,
                name: chains.value,
              }}
              onChange={handleChange}
              selectItems={DSIZE_SELECT_ITEMS}
              selectWithLabelProps={{
                id: chains.unit,
                name: chains.unit,
                onChange: (event) => {
                  const newUnit = event.target.value as DataSizeUnit;

                  const { value, unit } = formik.values.size;

                  const newDataSize = dSize(value, {
                    fromUnit: unit,
                    precision: newUnit === 'B' ? 0 : undefined,
                    toUnit: newUnit,
                  });

                  if (!newDataSize) return;

                  const { value: newValue } = newDataSize;

                  formik.setFieldValue(
                    chains.size,
                    {
                      value: newValue,
                      unit: newUnit,
                    },
                    true,
                  );
                },
                value: formik.values.size.unit,
              }}
              value={formik.values.size.value}
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
