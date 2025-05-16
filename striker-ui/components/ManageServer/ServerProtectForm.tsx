import { Box, Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { capitalize } from 'lodash';
import { useMemo, useState } from 'react';

import { toHostDetailCalcableList } from '../../lib/api_converters';
import Autocomplete from '../Autocomplete';
import ContainedButton from '../ContainedButton';
import handleAction from './handleAction';
import handleFormSubmit from './handleFormSubmit';
import JobProgressList from '../JobProgressList';
import List from '../List';
import MessageBox from '../MessageBox';
import MessageGroup from '../MessageGroup';
import { protectSchema } from './schemas';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import Spinner from '../Spinner';
import SwitchWithLabel from '../SwitchWithLabel';
import { BodyText, InlineMonoText } from '../Text';
import useFetch from '../../hooks/useFetch';
import useFormikUtils from '../../hooks/useFormikUtils';

const nZero = BigInt(0);

const protocolOptions: SelectItem[] = [
  {
    displayValue: (
      <Box>
        <BodyText inheritColour>
          Async (
          <InlineMonoText inheritColour noWrap>
            short-throw
          </InlineMonoText>
          )
        </BodyText>
        <BodyText selected={false}>
          Replication writes are considered done when the data is in the active
          node&apos;s network transmit buffer.
        </BodyText>
      </Box>
    ),
    value: 'short-throw',
  },
  {
    displayValue: (
      <Box>
        <BodyText inheritColour>Sync</BodyText>
        <BodyText selected={false}>
          Replication writes are considered done when the data is written to
          disk on the DR host.
        </BodyText>
      </Box>
    ),
    value: 'sync',
  },
];

const BaseServerProtectForm: React.FC<BaseServerProtectFormProps> = (props) => {
  const { detail, drs, tools } = props;

  const [jobProgress, setJobProgress] = useState<number>(0);

  const [jobRegistered, setJobRegistered] = useState<boolean>(false);

  const jobInProgress = useMemo<boolean>(
    () => jobRegistered && jobProgress < 100,
    [jobRegistered, jobProgress],
  );

  const url = useMemo<string>(
    () => `/server/${detail.uuid}/set-protect`,
    [detail.uuid],
  );

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
      setJobRegistered(false);

      handleFormSubmit(
        values,
        helpers,
        tools,
        () => url,
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
          onSuccess: () => {
            setJobRegistered(true);
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

    const connected = status.connection === 'connected';

    return (
      <Grid alignItems="center" container spacing="1em">
        <Grid item width="100%">
          <BodyText>
            <InlineMonoText edge="start" noWrap>
              {detail.name}
            </InlineMonoText>{' '}
            is configured to be protected by{' '}
            <InlineMonoText noWrap>{dr.short}</InlineMonoText> using protocol{' '}
            <InlineMonoText noWrap>{protocol}</InlineMonoText>.
          </BodyText>
        </Grid>
        <Grid item xs>
          <SwitchWithLabel
            checked={connected}
            label="Connection"
            onChange={(event, checked) => {
              const operation = checked ? 'connect' : 'disconnect';

              const label = capitalize(operation);

              handleAction(
                tools,
                url,
                `${label} the server on the protector DR host?`,
                {
                  body: {
                    operation,
                  },
                  description: (
                    <BodyText>
                      {operation === 'connect' ? (
                        <>
                          This operation connects the server to its copy on the
                          DR host and start streaming replication.
                        </>
                      ) : (
                        <>
                          This operation disconnects the server from its copy on
                          the DR host and stop streaming replication.
                        </>
                      )}
                    </BodyText>
                  ),
                  messages: {
                    fail: <>Failed to register {operation} resource job.</>,
                    proceed: label,
                    success: (
                      <>Successfully registered {operation} resource job</>
                    ),
                  },
                },
              );
            }}
          />
        </Grid>
        <Grid item xs>
          <ContainedButton
            onClick={() => {
              const operation = 'update';

              const label = capitalize(operation);

              handleAction(
                tools,
                url,
                `${label} the server on the protector DR host?`,
                {
                  body: {
                    operation,
                  },
                  description: (
                    <BodyText>
                      This operation is a combination that connects, performs a
                      sync, and disconnects.
                    </BodyText>
                  ),
                  messages: {
                    fail: <>Failed to register {operation} resource job.</>,
                    proceed: label,
                    success: (
                      <>Successfully registered {operation} resource job</>
                    ),
                  },
                },
              );
            }}
            sx={{
              width: '100%',
            }}
          >
            Update
          </ContainedButton>
        </Grid>
        <Grid item xs>
          <ContainedButton
            background="red"
            onClick={() => {
              const operation = 'remove';

              const label = capitalize(operation);

              handleAction(
                tools,
                url,
                `${label} protection for the server on the protector DR host?`,
                {
                  body: {
                    operation,
                  },
                  description: (
                    <BodyText>
                      This operation removes the server&apos;s copy on the DR
                      host and thus removes the protection.
                    </BodyText>
                  ),
                  dangerous: true,
                  messages: {
                    fail: <>Failed to register {operation} protection job.</>,
                    proceed: label,
                    success: (
                      <>Successfully registered {operation} protection job</>
                    ),
                  },
                },
              );
            }}
            sx={{
              width: '100%',
            }}
          >
            Remove protection
          </ContainedButton>
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
                  <InlineMonoText edge="start" noWrap>
                    {lv.name}
                  </InlineMonoText>{' '}
                  (
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
          selectProps={{
            renderValue: (value) => value,
          }}
          value={formik.values.protocol}
        />
      </Grid>
      {jobRegistered && (
        <Grid item width="100%">
          <JobProgressList
            getLabel={(progress) =>
              progress === 100 ? 'Config changed.' : 'Changing config...'
            }
            names={[
              'dr::link',
              'dr::protect',
              `storage-group-member::add::${formik.values.lvmVgUuid}`,
            ]}
            progress={{
              set: setJobProgress,
              value: jobProgress,
            }}
          />
        </Grid>
      )}
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ServerFormSubmit
          detail={detail}
          formDisabled={disabledSubmit || jobInProgress}
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
