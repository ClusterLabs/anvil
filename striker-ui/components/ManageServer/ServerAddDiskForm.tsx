import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';
import {
  DataSizeUnit,
  dSize,
  dSizeStr,
  FormatDataSizeOptions,
} from 'format-data-size';

import { DSIZE_SELECT_ITEMS } from '../../lib/consts/DSIZES';

import { toAnvilSharedStorageOverview } from '../../lib/api_converters';
import { StorageBar } from '../Bars';
import MessageGroup from '../MessageGroup';
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import { buildAddDiskSchema } from './schemas';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFetch from '../../hooks/useFetch';
import useFormikUtils from '../../hooks/useFormikUtils';

const DEFAULT_UNIT: DataSizeUnit = 'GiB';

const UNIT_OPTIONS: SelectItem<DataSizeUnit | 'percent'>[] = [
  ...DSIZE_SELECT_ITEMS,
  {
    displayValue: '%',
    value: 'percent',
  },
];

const ServerAddDiskForm: FC<ServerAddDiskFormProps> = (props) => {
  const { device, detail } = props;

  const working = useMemo(
    () => detail.devices.disks.find((disk) => disk.target.dev === device),
    [detail.devices.disks, device],
  );

  const { altData: sgs } = useFetch<
    AnvilSharedStorage,
    APIAnvilSharedStorageOverview
  >(`/anvil/${detail.anvil.uuid}/store`, {
    mod: toAnvilSharedStorageOverview,
    refreshInterval: 5000,
  });

  const formikUtils = useFormikUtils<ServerAddDiskFormikValues>({
    initialValues: {
      size: {
        unit: DEFAULT_UNIT,
        value: '0',
      },
      storage: working?.source.dev.sg ?? '',
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: buildAddDiskSchema(sgs),
  });
  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(() => {
    const base = 'size';

    return {
      size: base,
      storage: 'storage',
      unit: `${base}.unit`,
      value: `${base}.value`,
    };
  }, []);

  const sgValues = useMemo<SelectItem[] | undefined>(
    () =>
      sgs &&
      Object.values(sgs.storageGroups).map<SelectItem>((sg) => ({
        displayValue: sg.name,
        value: sg.uuid,
      })),
    [sgs],
  );

  const formattedSg = useMemo(() => {
    if (!sgs) return undefined;

    const { size, storage } = formik.values;
    const { [storage]: sg } = sgs.storageGroups;

    if (!sg) return undefined;

    const options: FormatDataSizeOptions = {
      toUnit:
        size.unit === 'percent' ? DEFAULT_UNIT : (size.unit as DataSizeUnit),
    };

    return {
      free: dSizeStr(sg.free, options),
      size: dSizeStr(sg.size, options),
      used: dSizeStr(sg.used, options),
    };
  }, [formik.values, sgs]);

  const disableStorageGroup = useMemo(() => Boolean(device), [device]);

  const disableDiskSize = useMemo(
    () => !formik.values.storage,
    [formik.values.storage],
  );

  if (!sgs || !sgValues) {
    return <Spinner mt={0} />;
  }

  return (
    <ServerFormGrid<ServerAddDiskFormikValues> formik={formik}>
      {formattedSg && (
        <Grid item width="100%">
          <StorageBar storages={sgs} target={formik.values.storage} />
          <Grid container>
            <Grid item>
              <BodyText>Used: {formattedSg.used}</BodyText>
            </Grid>
            <Grid item textAlign="center" xs>
              <BodyText fontWeight={400}>Free: {formattedSg.free}</BodyText>
            </Grid>
            <Grid item textAlign="right">
              <BodyText>Total: {formattedSg.size}</BodyText>
            </Grid>
          </Grid>
        </Grid>
      )}
      <Grid item sm xs={1}>
        <SelectWithLabel
          id={chains.storage}
          label="Storage group"
          name={chains.storage}
          onChange={formik.handleChange}
          selectItems={sgValues}
          selectProps={{
            disabled: disableStorageGroup,
          }}
          value={formik.values.storage}
        />
      </Grid>
      <Grid item sm xs={1}>
        <UncontrolledInput
          input={
            <OutlinedLabeledInputWithSelect
              id="server-disk-input"
              label="Disk size"
              inputWithLabelProps={{
                id: chains.value,
                inputProps: {
                  disabled: disableDiskSize,
                },
                name: chains.value,
              }}
              onChange={handleChange}
              selectItems={UNIT_OPTIONS}
              selectWithLabelProps={{
                id: chains.unit,
                name: chains.unit,
                onChange: (event) => {
                  const newUnit = event.target.value;

                  if (newUnit === 'percent') {
                    return;
                  }

                  const { unit, value } = formik.values.size;

                  if (unit === 'percent') {
                    return;
                  }

                  const newDataSize = dSize(value, {
                    fromUnit: unit as DataSizeUnit,
                    precision: newUnit === 'B' ? 0 : undefined,
                    toUnit: newUnit as DataSizeUnit,
                  });

                  if (!newDataSize) return;

                  const { value: newValue } = newDataSize;

                  formik.setFieldValue(
                    chains.size,
                    {
                      unit: newUnit,
                      value: newValue,
                    },
                    true,
                  );
                },
                selectProps: {
                  disabled: disableDiskSize,
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

export default ServerAddDiskForm;
