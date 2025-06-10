import {
  Grid2 as MuiGrid,
  grid2Classes as muiGridClasses,
} from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { StorageBar } from '../Bars';
import Divider from '../Divider';
import { BodyText, InlineMonoText, MonoText } from '../Text';

const HostStorageList: React.FC<HostStorageListProps> = (props) => {
  const { host } = props;

  const { volumeGroups, volumeGroupTotals } = host.storage;

  const total = useMemo(() => {
    const { free: nFree, size: nSize, used: nUsed } = volumeGroupTotals;

    const free = dSizeStr(nFree, { toUnit: 'ibyte' });
    const size = dSizeStr(nSize, { toUnit: 'ibyte' });
    const used = dSizeStr(nUsed, { toUnit: 'ibyte' });

    return (
      <MuiGrid width="100%">
        <BodyText>Total</BodyText>
        <StorageBar volume={volumeGroupTotals} />
        <MuiGrid container width="100%">
          <MuiGrid>
            <BodyText>Used: {used}</BodyText>
          </MuiGrid>
          <MuiGrid size="grow" textAlign="center">
            <BodyText fontWeight={400}>Free: {free}</BodyText>
          </MuiGrid>
          <MuiGrid textAlign="right">
            <BodyText>Size: {size}</BodyText>
          </MuiGrid>
        </MuiGrid>
      </MuiGrid>
    );
  }, [volumeGroupTotals]);

  const vgs = useMemo(() => {
    const ls = Object.values(volumeGroups).map<React.ReactNode>((vg) => {
      const { free: nFree, internalUuid, name, size: nSize, uuid } = vg;

      const free = dSizeStr(nFree, { toUnit: 'ibyte' });
      const size = dSizeStr(nSize, { toUnit: 'ibyte' });

      return (
        <MuiGrid key={`vg-${uuid}`}>
          <MuiGrid alignItems="center" container width="100%">
            <MuiGrid size="grow">
              <BodyText noWrap>{name}</BodyText>
            </MuiGrid>
            <MuiGrid>
              <BodyText variant="caption">
                Free <InlineMonoText>{free}</InlineMonoText>/
                <InlineMonoText edge="end">{size}</InlineMonoText>
              </BodyText>
            </MuiGrid>
            <MuiGrid width="100%">
              <StorageBar thin volume={vg} />
            </MuiGrid>
            <MuiGrid width="100%">
              <MonoText noWrap variant="caption">
                {internalUuid}
              </MonoText>
            </MuiGrid>
          </MuiGrid>
        </MuiGrid>
      );
    });

    return (
      <MuiGrid width="100%">
        <MuiGrid
          container
          spacing="1em"
          sx={{
            width: '100%',

            [`& > .${muiGridClasses.root}`]: {
              width: {
                xs: '100%',
                lg: '50%',
                xl: 'calc(100% / 3)',
              },
            },
          }}
        >
          {ls}
        </MuiGrid>
      </MuiGrid>
    );
  }, [volumeGroups]);

  return (
    <MuiGrid alignItems="center" container spacing="1em" width="100%">
      {total}
      <MuiGrid>
        <BodyText>Volume Groups</BodyText>
      </MuiGrid>
      <MuiGrid size="grow">
        <Divider />
      </MuiGrid>
      {vgs}
    </MuiGrid>
  );
};

export default HostStorageList;
