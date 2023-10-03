import { Grid, gridClasses, typographyClasses } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { FC, ReactNode, useMemo } from 'react';

import { BLUE, GREY, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';

import {
  toAnvilDetail,
  toAnvilMemoryCalcable,
  toAnvilSharedStorageOverview,
} from '../../lib/api_converters';
import FlexBox from '../FlexBox';
import Spinner from '../Spinner';
import StackBar from '../Bars/StackBar';
import { BodyText, InlineMonoText, MonoText } from '../Text';
import useFetch from '../../hooks/useFetch';

const N_100 = BigInt(100);

const MAP_TO_ANVIL_STATE_COLOUR = {
  degraded: RED,
  not_ready: PURPLE,
  optimal: BLUE,
};

const MAP_TO_HOST_STATE_COLOUR: Record<string, string> = {
  offline: PURPLE,
  online: BLUE,
};

const AnvilSummary: FC<AnvilSummaryProps> = (props) => {
  const { anvilUuid } = props;

  const { data: rAnvil, loading: loadingAnvil } = useFetch<AnvilListItem>(
    `/anvil/${anvilUuid}`,
  );

  const anvil = useMemo<APIAnvilDetail | undefined>(
    () => rAnvil && toAnvilDetail(rAnvil),
    [rAnvil],
  );

  const { data: cpu, loading: loadingCpu } = useFetch<AnvilCPU>(
    `/anvil/${anvilUuid}/cpu`,
  );

  const cpuSubnodes = useMemo<AnvilCPU['hosts'][string][] | undefined>(
    () => cpu && Object.values(cpu.hosts),
    [cpu],
  );

  const { data: rMemory, loading: loadingMemory } = useFetch<AnvilMemory>(
    `/anvil/${anvilUuid}/memory`,
  );

  const memory = useMemo<AnvilMemoryCalcable | undefined>(
    () => rMemory && toAnvilMemoryCalcable(rMemory),
    [rMemory],
  );

  const { data: rStorages, loading: loadingStorages } =
    useFetch<AnvilSharedStorage>(`/anvil/${anvilUuid}/store`);

  const storages = useMemo<APIAnvilSharedStorageOverview | undefined>(
    () => rStorages && toAnvilSharedStorageOverview(rStorages),
    [rStorages],
  );

  const loading = useMemo<boolean>(
    () =>
      [loadingAnvil, loadingCpu, loadingMemory, loadingStorages].some(
        (cond) => cond,
      ),
    [loadingAnvil, loadingCpu, loadingMemory, loadingStorages],
  );

  const anvilSummary = useMemo(
    () =>
      anvil && (
        <MonoText inheritColour color={MAP_TO_ANVIL_STATE_COLOUR[anvil.state]}>
          {anvil.state}
        </MonoText>
      ),
    [anvil],
  );

  const hostsSummary = useMemo(
    () =>
      anvil && (
        <FlexBox
          spacing={0}
          sx={{
            [`& > .${typographyClasses.root}:first-child`]: {
              marginBottom: '-.6em',
            },
          }}
        >
          {Object.values(anvil.hosts).map<ReactNode>((host) => {
            const { name, state, stateProgress, uuid } = host;

            const stateColour: string = MAP_TO_HOST_STATE_COLOUR[state] ?? GREY;

            let stateValue: string = state;

            if (!['offline', 'online'].includes(state)) {
              stateValue = `${stateProgress}%`;
            }

            return (
              <BodyText
                key={`anvil-summary-host-${uuid}`}
                variant="caption"
                whiteSpace="nowrap"
              >
                {name}{' '}
                <InlineMonoText inheritColour color={stateColour}>
                  {stateValue}
                </InlineMonoText>
              </BodyText>
            );
          })}
        </FlexBox>
      ),
    [anvil],
  );

  const cpuSummary = useMemo(
    () =>
      cpu &&
      cpuSubnodes && (
        <FlexBox row>
          <FlexBox spacing={0}>
            <BodyText variant="caption" whiteSpace="nowrap">
              Vendor <InlineMonoText>{cpuSubnodes[0].vendor}</InlineMonoText>
            </BodyText>
          </FlexBox>
          <Grid
            columns={2}
            container
            minWidth="calc(0% + 4em)"
            sx={{
              [`& > .${gridClasses.item}:nth-child(-n + 2)`]: {
                marginBottom: '-.6em',
              },
            }}
            width="calc(0% + 4em)"
          >
            <Grid item xs={1}>
              <BodyText variant="caption">Cores</BodyText>
            </Grid>
            <Grid display="flex" item justifyContent="flex-end" xs={1}>
              <MonoText variant="caption">{cpu.cores}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText variant="caption">Threads</BodyText>
            </Grid>
            <Grid display="flex" item justifyContent="flex-end" xs={1}>
              <MonoText variant="caption">{cpu.threads}</MonoText>
            </Grid>
          </Grid>
        </FlexBox>
      ),
    [cpu, cpuSubnodes],
  );

  const memorySummary = useMemo(
    () =>
      memory && (
        <FlexBox spacing={0}>
          <FlexBox row justifyContent="flex-end">
            <BodyText mb="-.3em" variant="caption">
              Free
              <InlineMonoText>
                {dSizeStr(memory.total - (memory.reserved + memory.allocated), {
                  toUnit: 'ibyte',
                })}
              </InlineMonoText>
              /
              <InlineMonoText sx={{ paddingRight: 0 }}>
                {dSizeStr(memory.total, { toUnit: 'ibyte' })}
              </InlineMonoText>
            </BodyText>
          </FlexBox>
          <StackBar
            thin
            value={{
              reserved: {
                value: Number((memory.reserved * N_100) / memory.total),
              },
              allocated: {
                value: Number(
                  ((memory.reserved + memory.allocated) * N_100) / memory.total,
                ),
                colour: { 0: BLUE, 70: PURPLE, 90: RED },
              },
            }}
          />
        </FlexBox>
      ),
    [memory],
  );

  const storeSummary = useMemo(
    () =>
      storages && (
        <FlexBox spacing={0}>
          <FlexBox row justifyContent="flex-end">
            <BodyText mb="-.3em" variant="caption">
              Total free
              <InlineMonoText>
                {dSizeStr(storages.totalFree, { toUnit: 'ibyte' })}
              </InlineMonoText>
              /
              <InlineMonoText sx={{ paddingRight: 0 }}>
                {dSizeStr(storages.totalSize, { toUnit: 'ibyte' })}
              </InlineMonoText>
            </BodyText>
          </FlexBox>
          <StackBar
            thin
            value={{
              allocated: {
                value: Number(
                  ((storages.totalSize - storages.totalFree) * N_100) /
                    storages.totalSize,
                ),
                colour: { 0: BLUE, 70: PURPLE, 90: RED },
              },
            }}
          />
        </FlexBox>
      ),
    [storages],
  );

  return loading ? (
    <Spinner mt={0} />
  ) : (
    <Grid
      alignItems="center"
      columns={3}
      container
      sx={{
        [`& > .${gridClasses.item}:nth-child(odd)`]: {
          alignItems: 'center',
          display: 'flex',
          height: '2.5em',
        },
      }}
    >
      <Grid item xs={1}>
        <BodyText>Node</BodyText>
      </Grid>
      <Grid item xs={2}>
        {anvilSummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>Subnodes</BodyText>
      </Grid>
      <Grid item xs={2}>
        {hostsSummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>CPU</BodyText>
      </Grid>
      <Grid item xs={2}>
        {cpuSummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>Memory</BodyText>
      </Grid>
      <Grid item xs={2}>
        {memorySummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>Storage</BodyText>
      </Grid>
      <Grid item xs={2}>
        {storeSummary}
      </Grid>
    </Grid>
  );
};

export default AnvilSummary;
