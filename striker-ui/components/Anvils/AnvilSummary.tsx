import { Grid, gridClasses } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { FC, useMemo } from 'react';

import { BLUE, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';

import {
  toAnvilMemoryCalcable,
  toAnvilSharedStorageOverview,
} from '../../lib/api_converters';
import FlexBox from '../FlexBox';
import Spinner from '../Spinner';
import StackBar from '../Bars/StackBar';
import { BodyText, InlineMonoText, MonoText } from '../Text';
import useFetch from '../../hooks/useFetch';

const n100 = BigInt(100);

const AnvilSummary: FC<AnvilSummaryProps> = (props) => {
  const { anvilUuid } = props;

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
    () => loadingCpu || loadingMemory || loadingStorages,
    [loadingCpu, loadingMemory, loadingStorages],
  );

  const cpuSummary = useMemo(
    () =>
      cpu &&
      cpuSubnodes && (
        <FlexBox justifyContent="center" row>
          <FlexBox spacing={0}>
            <BodyText variant="caption">{cpuSubnodes[0].name}</BodyText>
            <MonoText>{cpuSubnodes[0].vendor}</MonoText>
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
              <BodyText variant="caption">CORES</BodyText>
            </Grid>
            <Grid display="flex" item justifyContent="flex-end" xs={1}>
              <MonoText variant="caption">{cpu.cores}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText variant="caption">THREADS</BodyText>
            </Grid>
            <Grid display="flex" item justifyContent="flex-end" xs={1}>
              <MonoText variant="caption">{cpu.threads}</MonoText>
            </Grid>
          </Grid>
          <FlexBox spacing={0}>
            <BodyText variant="caption">{cpuSubnodes[1].name}</BodyText>
            <MonoText>{cpuSubnodes[1].vendor}</MonoText>
          </FlexBox>
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
              FREE
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
                value: Number((memory.reserved * n100) / memory.total),
              },
              allocated: {
                value: Number(
                  ((memory.reserved + memory.allocated) * n100) / memory.total,
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
              FREE
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
                  ((storages.totalSize - storages.totalFree) * n100) /
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
