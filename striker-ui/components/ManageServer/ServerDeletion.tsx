import { Grid } from '@mui/material';

import ContainedButton from '../ContainedButton';
import handleAction from './handleAction';
import { BodyText } from '../Text';

const ServerDeletion: React.FC<ServerDeletionProps> = (props) => {
  const { detail, tools } = props;

  return (
    <Grid container spacing="1em">
      <Grid item width="100%">
        <BodyText>
          Server {detail.name} is in {detail.state}
        </BodyText>
      </Grid>
      <Grid item>
        <ContainedButton
          onClick={() => {
            handleAction(
              tools,
              `/server/${detail.uuid}`,
              `Delete server ${detail.name}?`,
              {
                dangerous: true,
                method: 'delete',
                messages: {
                  fail: <>Failed to register server deletion job.</>,
                  proceed: 'Delete',
                  success: <>Successfully registered server deletion job</>,
                },
              },
            );
          }}
        >
          Delete {detail.name}
        </ContainedButton>
      </Grid>
    </Grid>
  );
};

export default ServerDeletion;
