import { Grid } from '@mui/material';
import { FC } from 'react';

import ContainedButton from '../ContainedButton';
import handleAction from './handleAction';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import useFetch from '../../hooks/useFetch';

const ServerMigration: FC<ServerMigrationProps> = (props) => {
  const { detail, tools } = props;

  const { altData: peer } = useFetch<
    APIHostOverviewList,
    APIHostOverview | undefined
  >('/host?types=node', {
    mod: (data) => {
      const values = Object.values(data);

      return values.find(
        (host) =>
          host.anvil?.uuid === detail.anvil.uuid &&
          host.shortHostName !== detail.host.short,
      );
    },
  });

  if (!peer) {
    return <Spinner mt={0} />;
  }

  return (
    <Grid container spacing="1em">
      <Grid item width="100%">
        <BodyText>Running on: {detail.host.short}</BodyText>
      </Grid>
      <Grid item>
        <ContainedButton
          onClick={() => {
            handleAction(
              tools,
              `/server/${detail.uuid}/migrate`,
              `Migrate ${detail.name} to ${peer.shortHostName}?`,
              {
                body: {
                  target: peer.shortHostName,
                },
                messages: {
                  fail: <>Failed to register migration job.</>,
                  proceed: 'Migrate',
                  success: <>Successfully register migration job</>,
                },
              },
            );
          }}
        >
          Migrate to {peer.shortHostName}
        </ContainedButton>
      </Grid>
    </Grid>
  );
};

export default ServerMigration;
