import { Add as MuiAddIcon } from '@mui/icons-material';
import { Grid } from '@mui/material';
import {
  DataSizeUnit,
  dSize,
  dSizeStr,
  FormatDataSizeOptions,
} from 'format-data-size';
import { useMemo } from 'react';

import { GREY } from '../../lib/consts/DEFAULT_THEME';
import { DSIZE_SELECT_ITEMS } from '../../lib/consts/DSIZES';

import { toAnvilSharedStorageOverview } from '../../lib/api_converters';
import { StorageBar } from '../Bars';
import handleFormSubmit from './handleFormSubmit';
import MessageBox from '../MessageBox';
import MessageGroup from '../MessageGroup';
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import { buildAddDiskSchema } from './schemas';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import Spinner from '../Spinner';
import { BodyText, InlineMonoText } from '../Text';
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

const ServerAddDiskForm: React.FC<ServerAddDiskFormProps> = (props) => {
  const { device, detail, tools } = props;

  const working = useMemo(
    () => detail.devices.disks.find((disk) => disk.target.dev === device),
    [detail.devices.disks, device],
  );

  const { altData: sgs } = useFetch<
    APIAnvilStorageList,
    APIAnvilSharedStorageOverview
  >(`/anvil/${detail.anvil.uuid}/storage`, {
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
    onSubmit: (values, helpers) => {
      handleFormSubmit(
        values,
        helpers,
        tools,
        () => `/server/${detail.uuid}/${device ? 'grow-disk' : 'add-disk'}`,
        () => `Add disk on ${sgs?.storageGroups[values.storage].name}?`,
        {
          buildSummary: (v) => {
            const { size, storage } = v;
            const { unit: option, value } = size;

            const unit = /percent/i.test(option) ? '%' : option;

            if (device) {
              return {
                device,
                size: `${value}${unit}`,
              };
            }

            return {
              size: `${value}${unit}`,
              storage: sgs?.storageGroups[storage].name,
            };
          },
          buildRequestBody: (v, s) => {
            if (s?.storage) {
              s.storage = v.storage;
            }

            return s;
          },
        },
      );
    },
    validationSchema: buildAddDiskSchema(sgs),
  });
  const {
    disabledSubmit: formikDisabledSubmit,
    formik,
    formikErrors,
    handleChange,
  } = formikUtils;

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

  const sg = useMemo(() => {
    if (!sgs) return undefined;

    return sgs.storageGroups[formik.values.storage];
  }, [formik.values, sgs]);

  const formatUnit = useMemo(() => {
    const { unit } = formik.values.size;

    if (unit === 'percent') {
      return DEFAULT_UNIT;
    }

    return unit as DataSizeUnit;
  }, [formik.values.size]);

  const formattedSg = useMemo(() => {
    if (!sg) return undefined;

    const options: FormatDataSizeOptions = {
      toUnit: formatUnit,
    };

    return {
      free: dSizeStr(sg.free, options),
      size: dSizeStr(sg.size, options),
      used: dSizeStr(sg.used, options),
    };
  }, [formatUnit, sg]);

  const formattedWorking = useMemo(() => {
    if (!working) return undefined;

    const { name = '', size } = working.source.dev.lv;

    if (!size) return undefined;

    const options: FormatDataSizeOptions = {
      toUnit: formatUnit,
    };

    return {
      name,
      size: dSizeStr(size, options),
      zero: /_0$/.test(name),
    };
  }, [formatUnit, working]);

  const disabledSubmit = useMemo(
    () =>
      (detail.state !== 'shut off' && formattedWorking?.zero) ||
      formikDisabledSubmit,
    [detail.state, formattedWorking?.zero, formikDisabledSubmit],
  );

  const growMsg = useMemo(() => {
    if (detail.state === 'shut off') {
      return undefined;
    }

    if (!formattedWorking?.zero) {
      return undefined;
    }

    return (
      <Grid item width="100%">
        <MessageBox>
          A server must be shut off in order to grow its disk 0.
        </MessageBox>
      </Grid>
    );
  }, [detail.state, formattedWorking?.zero]);

  const graph = useMemo(
    () =>
      formattedSg &&
      sgs && (
        <Grid item width="100%">
          <BodyText>
            Storage group: <InlineMonoText noWrap>{sg?.name}</InlineMonoText>
          </BodyText>
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
      ),
    [formattedSg, formik.values.storage, sg?.name, sgs],
  );

  const growBySymbol = useMemo(
    () =>
      device && (
        <Grid item textAlign="center" width={{ xs: '100%', sm: 'fit-content' }}>
          <MuiAddIcon sx={{ color: GREY }} />
        </Grid>
      ),
    [device],
  );

  if (!sgValues) {
    return <Spinner mt={0} />;
  }

  return (
    <ServerFormGrid<ServerAddDiskFormikValues>
      alignItems="center"
      formik={formik}
    >
      {growMsg}
      {graph}
      <Grid item sm xs={1}>
        {device ? (
          <Grid alignItems="center" container>
            <Grid item xs>
              <BodyText>
                Disk: <InlineMonoText noWrap>{device}</InlineMonoText>
              </BodyText>
              <BodyText>
                (
                <InlineMonoText>volume={formattedWorking?.name}</InlineMonoText>
                )
              </BodyText>
            </Grid>
            <Grid item>
              <BodyText fontWeight={400} noWrap>
                {formattedWorking?.size}
              </BodyText>
            </Grid>
          </Grid>
        ) : (
          <SelectWithLabel
            id={chains.storage}
            label="Storage group"
            name={chains.storage}
            onChange={formik.handleChange}
            selectItems={sgValues}
            selectProps={{
              disabled: Boolean(device),
            }}
            value={formik.values.storage}
          />
        )}
      </Grid>
      {growBySymbol}
      <Grid item sm xs={1}>
        <UncontrolledInput
          input={
            <OutlinedLabeledInputWithSelect
              id="server-disk-input"
              label="Disk size"
              inputWithLabelProps={{
                id: chains.value,
                inputProps: {
                  disabled: !formik.values.storage,
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

                  const { unit, value } = formik.values.size;

                  if ([newUnit, unit].includes('percent')) {
                    formik.setFieldValue(
                      chains.size,
                      {
                        unit: newUnit,
                        value: '0',
                      },
                      true,
                    );

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
                  disabled: !formik.values.storage,
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
