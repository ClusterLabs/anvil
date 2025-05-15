import { Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { toHostDetailCalcableList } from '../../lib/api_converters';
import Autocomplete from '../Autocomplete';
import handleFormSubmit from './handleFormSubmit';
import MessageBox from '../MessageBox';
import MessageGroup from '../MessageGroup';
import { protectSchema } from './schemas';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import Spinner from '../Spinner';
import { BodyText, InlineMonoText } from '../Text';
import useFetch from '../../hooks/useFetch';
import useFormikUtils from '../../hooks/useFormikUtils';
import List from '../List';
import SwitchWithLabel from '../SwitchWithLabel';
import ContainedButton from '../ContainedButton';

const nZero = BigInt(0);

const protocolOptions: SelectItem[] = [
  {
    displayValue: 'Async',
    value: 'short-throw',
  },
  {
    displayValue: 'Sync',
    value: 'sync',
  },
];

const BaseServerProtectForm: React.FC<BaseServerProtectFormProps> = (props) => {
  const { detail, drs, tools } = props;

  const drVgs = useMemo(
    () =>
      Object.values(drs).reduce<Record<string, APIAnvilVolumeGroupCalcable>>(
        (previous, dr) => {
          Object.values(dr.storage.volumeGroups).forEach((vg) => {
            previous[vg.internalUuid] = vg;
          });

          return previous;
        },
        {},
      ),
    [drs],
  );

  const drVgOptions = useMemo(
    () => Object.values(drVgs).map<string>((vg) => vg.internalUuid),
    [drVgs],
  );

  const serverLvs = useMemo(
    () =>
      Object.values(detail.devices.disks).reduce<
        Record<string, APIServerDetailDisk['source']['dev']['lv']>
      >((previous, disk) => {
        const { lv } = disk.source.dev;

        if (lv.uuid) {
          previous[lv.uuid] = lv;
        }

        return previous;
      }, {}),
    [detail.devices.disks],
  );

  const serverProtect = useMemo(
    () => Object.values(detail.protect)[0],
    [detail.protect],
  );

  const serverTotalLvSize = useMemo<bigint>(() => {
    const lvSizes = Object.values(serverLvs).map<bigint>((lv) => {
      const { size } = lv;

      if (!size) {
        return nZero;
      }

      try {
        return BigInt(size);
      } catch (error) {
        return nZero;
      }
    });

    return lvSizes.reduce<bigint>((previous, size) => previous + size, nZero);
  }, [serverLvs]);

  const formikUtils = useFormikUtils<ServerProtectFormikValues>({
    initialValues: {
      lvmVgUuid: null,
      protocol: 'sync',
    },
    onSubmit: (values, helpers) => {
      handleFormSubmit(
        values,
        helpers,
        tools,
        () => `/server/${detail.uuid}/set-protect`,
        () => `Update server protect config?`,
        {
          buildSummary: (v) => {
            const { lvmVgUuid, protocol } = v;

            if (!lvmVgUuid) {
              return {};
            }

            const { [lvmVgUuid]: vg } = drVgs;

            const { [vg.host]: dr } = drs;

            return {
              drHost: dr.short,
              volumeGroup: `${vg.name} (${vg.internalUuid})`,
              protocol,
            };
          },
          buildRequestBody: (v) => {
            const { lvmVgUuid, protocol } = v;

            const body: APIServerProtectRequestBody = {
              operation: 'protect',
            };

            if (lvmVgUuid) {
              body.lvmVgUuid = lvmVgUuid;
            }

            if (protocol) {
              body.protocol = protocol;
            }

            return body;
          },
        },
      );
    },
    validationSchema: protectSchema,
  });

  const { changeFieldValue, disabledSubmit, formik, formikErrors } =
    formikUtils;

  const chains = useMemo(
    () => ({
      lvmVgUuid: 'lvmVgUuid',
      protocol: 'protocol',
    }),
    [],
  );

  if (serverProtect) {
    const { drUuid = '', protocol, status } = serverProtect;

    const { [drUuid]: dr } = drs;

    return (
      <Grid container spacing="1em">
        <Grid item width="100%">
          <BodyText>
            Server is configured to be protected by{' '}
            <InlineMonoText noWrap>{dr.short}</InlineMonoText> using protocol{' '}
            <InlineMonoText noWrap>{protocol}</InlineMonoText>.
          </BodyText>
        </Grid>
        <Grid item xs>
          <SwitchWithLabel
            checked={status.connection === 'connected'}
            label="Connection"
          />
        </Grid>
        <Grid item xs>
          <ContainedButton>Update</ContainedButton>
        </Grid>
      </Grid>
    );
  }

  return (
    <ServerFormGrid<ServerProtectFormikValues> formik={formik}>
      <Grid item width="100%">
        <List
          header="Server disk(s)"
          listItems={serverLvs}
          renderListItem={(key, lv) => (
            <Grid container>
              <Grid item xs>
                <BodyText>
                  <InlineMonoText noWrap>{lv.name}</InlineMonoText> (
                  <InlineMonoText noWrap variant="caption">
                    {lv.uuid}
                  </InlineMonoText>
                  )
                </BodyText>
              </Grid>
              <Grid item>
                <BodyText edge="end" noWrap>
                  {lv.size && dSizeStr(lv.size, { toUnit: 'ibyte' })}
                </BodyText>
              </Grid>
            </Grid>
          )}
        />
      </Grid>
      <Grid item width="100%">
        <BodyText>
          Server total disk(s) size:{' '}
          {dSizeStr(serverTotalLvSize, { toUnit: 'ibyte' })}
        </BodyText>
      </Grid>
      <Grid item xs={2}>
        <Autocomplete
          getOptionDisabled={(uuid) => {
            // check whether the vg that can contain the server
            const { [uuid]: vg } = drVgs;

            // disable when the vg doesn't have enough free space that fits the server total lv size
            return vg.free < serverTotalLvSize;
          }}
          getOptionLabel={(uuid) => {
            const { [uuid]: vg } = drVgs;

            const { [vg.host]: dr } = drs;

            return `${dr.short} - ${vg.name}`;
          }}
          id={chains.lvmVgUuid}
          label="Volume group"
          noOptionsText="No matching volume group"
          onChange={(event, value) => {
            changeFieldValue(chains.lvmVgUuid, value, true);
          }}
          openOnFocus
          options={drVgOptions}
          renderOption={(optionProps, uuid) => {
            const { [uuid]: vg } = drVgs;

            const { [vg.host]: dr } = drs;

            const status: React.ReactNode =
              vg.free >= serverTotalLvSize ? (
                <>Sufficient space</>
              ) : (
                <>Insufficient space</>
              );

            return (
              <li {...optionProps} key={`dr-op-${uuid}`}>
                <Grid alignItems="center" columnSpacing="1em" container>
                  <Grid item xs>
                    <BodyText edge="start" inheritColour>
                      <InlineMonoText edge="start" inheritColour noWrap>
                        {dr.short}
                      </InlineMonoText>{' '}
                      -{' '}
                      <InlineMonoText inheritColour noWrap>
                        {vg.name}
                      </InlineMonoText>
                    </BodyText>
                    <BodyText edge="start" inheritColour>
                      <InlineMonoText edge="start" inheritColour noWrap>
                        {dSizeStr(vg.free, { toUnit: 'ibyte' })}
                      </InlineMonoText>{' '}
                      free
                    </BodyText>
                  </Grid>
                  <Grid item>
                    <BodyText edge="end" inheritColour noWrap>
                      {status}
                    </BodyText>
                  </Grid>
                </Grid>
              </li>
            );
          }}
          required
          value={formik.values.lvmVgUuid}
        />
      </Grid>
      <Grid item xs={1}>
        <SelectWithLabel
          id={chains.protocol}
          label="Protocol"
          name={chains.protocol}
          onChange={formik.handleChange}
          required
          selectItems={protocolOptions}
          value={formik.values.protocol}
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

const ServerProtectForm: React.FC<ServerProtectFormProps> = (props) => {
  const {
    altData: drs,
    error: fetchError,
    loading,
  } = useFetch<APIHostDetailList, APIHostDetailCalcableList>(
    `/host?detail=1&type=dr`,
    {
      mod: toHostDetailCalcableList,
    },
  );

  if (loading) {
    return <Spinner mt={0} />;
  }

  if (!drs) {
    return (
      <MessageBox type="warning">
        Failed to get DR hosts. {fetchError?.message}
      </MessageBox>
    );
  }

  return <BaseServerProtectForm drs={drs} {...props} />;
};

export default ServerProtectForm;
