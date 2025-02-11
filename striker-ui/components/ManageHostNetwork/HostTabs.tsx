import { Grid, gridClasses as muiGridClasses } from '@mui/material';
import { FC } from 'react';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

import Tab from '../Tab';
import Tabs from '../Tabs';
import { BodyText, MonoText } from '../Text';

const HostTabs: FC<HostTabsProps> = (props) => {
  const { list: hostValues, setValue, value } = props;

  if (hostValues.length === 0) {
    return <BodyText>No host(s) found.</BodyText>;
  }

  return (
    <Tabs
      centered
      onChange={(event, hostUuid) => {
        setValue(hostUuid);
      }}
      orientation="vertical"
      value={value}
    >
      {hostValues.map((host) => {
        const {
          hostConfigured,
          hostStatus,
          hostType,
          hostUUID,
          shortHostName,
        } = host;

        const type = hostType.replace('dr', 'DR').replace('node', 'Subnode');

        return (
          <Tab
            key={`host-${hostUUID}`}
            label={
              <Grid
                container
                spacing="1em"
                sx={{
                  [`.${muiGridClasses.item}:not(:first-child)`]: {
                    borderLeft: `thin solid ${DIVIDER}`,
                  },
                }}
              >
                <Grid item xs>
                  <BodyText noWrap>{type}</BodyText>
                </Grid>
                <Grid item xs>
                  <MonoText noWrap>{shortHostName}</MonoText>
                </Grid>
                <Grid item xs>
                  <BodyText noWrap>
                    {hostStatus}
                    {hostConfigured ? ', configured' : ''}
                  </BodyText>
                </Grid>
              </Grid>
            }
            sx={{ textAlign: 'left' }}
            value={hostUUID}
          />
        );
      })}
    </Tabs>
  );
};

export default HostTabs;
