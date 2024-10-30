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
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import ServerFormSubmit from './ServerFormSubmit';
import ServerFormGrid from './ServerFormGrid';
import Spinner from '../Spinner';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';
import useFetch from '../../hooks/useFetch';
import { BodyText } from '../Text';

const ServerMemoryForm: FC<ServerMemoryFormProps> = (props) => {
  const { detail } = props;

  const { altData: summary } = useFetch<AnvilMemory, AnvilMemoryCalcable>(
    `/anvil/${detail.anvil.uuid}/memory`,
    {
      mod: toAnvilMemoryCalcable,
    },
  );

  const { disabledSubmit, formik, handleChange } =
    useFormikUtils<ServerMemoryFormikValues>({
      initialValues: {
        memory: {
          size:
            dSize(detail.memory.size, {
              fromUnit: 'B',
              toUnit: 'GiB',
            })?.value ?? '0',
          unit: 'GiB',
        },
      },
      onSubmit: (values, { setSubmitting }) => {
        setSubmitting(false);
      },
    });

  const chains = useMemo(() => {
    const base = 'memory';

    return {
      size: `${base}.size`,
      unit: `${base}.unit`,
    };
  }, []);

  const formattedSummary = useMemo(() => {
    if (!summary) return undefined;

    const options: FormatDataSizeOptions = {
      fromUnit: 'B',
      toUnit: formik.values.memory.unit,
    };

    const allocated = dSizeStr(summary.allocated, options) ?? '';
    const available = dSizeStr(summary.available, options) ?? '';
    const reserved = dSizeStr(summary.reserved, options) ?? '';
    const total = dSizeStr(summary.total, options) ?? '';

    return {
      allocated,
      available,
      reserved,
      total,
    };
  }, [formik.values.memory.unit, summary]);

  if (!summary || !formattedSummary) {
    return <Spinner mt={0} />;
  }

  return (
    <ServerFormGrid<ServerMemoryFormikValues> formik={formik}>
      <Grid item width="100%">
        <MemoryBar memory={summary} />
        <Grid container>
          <Grid item width="25%">
            <BodyText>Allocated: {formattedSummary.allocated}</BodyText>
            <BodyText>Reserved: {formattedSummary.reserved}</BodyText>
          </Grid>
          <Grid item width="50%" textAlign="center">
            <BodyText fontWeight={400}>
              Available: {formattedSummary.available}
            </BodyText>
          </Grid>
          <Grid item width="25%" textAlign="right">
            <BodyText>Total: {formattedSummary.total}</BodyText>
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
                  formik.handleChange(event);

                  const { value: newUnit } = event.target;
                  const { size, unit } = formik.values.memory;

                  const newDataSize = dSize(size, {
                    fromUnit: unit,
                    toUnit: newUnit as DataSizeUnit,
                  });

                  if (!newDataSize) return;

                  const { value: newSize } = newDataSize;

                  formik.setFieldValue(chains.size, newSize, true);
                },
                value: formik.values.memory.unit,
              }}
              value={formik.values.memory.size}
            />
          }
        />
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

export default ServerMemoryForm;
