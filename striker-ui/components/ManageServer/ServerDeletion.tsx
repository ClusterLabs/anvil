import { Grid } from '@mui/material';

import ContainedButton from '../ContainedButton';
import handleAction from './handleAction';
import { BodyText, InlineMonoText } from '../Text';

const ServerDeletion: React.FC<ServerDeletionProps> = (props) => {
  const { detail, tools } = props;

  return (
    <Grid container spacing="1em">
      <Grid item width="100%">
        <BodyText>
          Deleting <InlineMonoText>{detail.name}</InlineMonoText> will remove
          all of its data, including its configurations and storage volume(s).
        </BodyText>
      </Grid>
      <Grid item>
        <ContainedButton
          background="red"
          onClick={() => {
            handleAction(
              tools,
              `/server/${detail.uuid}`,
              `Delete server ${detail.name}?`,
              {
                description: (
                  <BodyText>
                    Are you sure you want to delete the server {detail.name}?
                    This action is not reversible!
                  </BodyText>
                ),
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
