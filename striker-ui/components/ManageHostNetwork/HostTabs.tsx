import MuiGrid, { grid2Classes as muiGridClasses } from '@mui/material/Grid2';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

import Tab from '../Tab';
import Tabs from '../Tabs';
import { BodyText, MonoText } from '../Text';

const HostTabs: React.FC<HostTabsProps> = (props) => {
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
              <MuiGrid
                columnSpacing="1em"
                container
                sx={{
                  width: '100%',

                  [`& > .${muiGridClasses.root}:not(:first-child)`]: {
                    borderLeft: `thin solid ${DIVIDER}`,
                    paddingLeft: '1em',
                  },
                }}
              >
                <MuiGrid size="grow">
                  <BodyText noWrap>{type}</BodyText>
                </MuiGrid>
                <MuiGrid size="grow">
                  <MonoText noWrap>{shortHostName}</MonoText>
                </MuiGrid>
                <MuiGrid size="grow">
                  <BodyText noWrap>
                    {hostStatus}
                    {hostConfigured ? ', configured' : ''}
                  </BodyText>
                </MuiGrid>
              </MuiGrid>
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
