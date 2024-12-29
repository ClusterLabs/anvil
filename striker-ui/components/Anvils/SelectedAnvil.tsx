import { Box, styled, Switch } from '@mui/material';
import { capitalize } from 'lodash';
import { useContext } from 'react';

import anvilState from '../../lib/consts/ANVILS';

import api from '../../lib/api';
import { AnvilContext } from '../AnvilContext';
import Decorator, { Colours } from '../Decorator';
import handleAPIError from '../../lib/handleAPIError';
import { HeaderText } from '../Text';
import useConfirmDialog from '../../hooks/useConfirmDialog';

const PREFIX = 'SelectedAnvil';

const classes = {
  anvilName: `${PREFIX}-anvilName`,
};

const StyledBox = styled(Box)(() => ({
  display: 'flex',
  flexDirection: 'row',
  width: '100%',

  [`& .${classes.anvilName}`]: {
    paddingLeft: 0,
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'optimal':
      return 'ok';
    case 'degraded':
      return 'warning';
    default:
      return 'off';
  }
};

const isAnvilOn = (anvil: AnvilListItem): boolean =>
  !(
    anvil.hosts.findIndex(
      ({ state }: AnvilStatusHost) => state !== 'offline',
    ) === -1
  );

const SelectedAnvil = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const index = list.findIndex(
    (anvil: AnvilListItem) => anvil.anvil_uuid === uuid,
  );

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog();

  return (
    <>
      <StyledBox>
        {uuid !== '' && (
          <>
            <Box p={1}>
              <Decorator
                colour={selectDecorator(list[index].anvilStatus.system)}
              />
            </Box>
            <Box p={1} flexGrow={1} className={classes.anvilName}>
              <HeaderText text={list[index].anvil_name} />
              <HeaderText
                text={
                  anvilState.get(list[index].anvilStatus.system) ??
                  'State unavailable'
                }
              />
            </Box>
            <Box p={1}>
              <Switch
                checked={isAnvilOn(list[index])}
                onChange={() => {
                  const { [index]: litem } = list;
                  const { anvil_name: anvilName, anvil_uuid: anvilUuid } =
                    litem;

                  let action: 'start' | 'stop' = 'start';
                  let content: React.ReactNode;
                  let proceedColour: 'blue' | 'red' = 'blue';

                  if (isAnvilOn(litem)) {
                    action = 'stop';
                    content = 'Servers hosted on this node will be shut down!';
                    proceedColour = 'red';
                  }

                  const command = `${action}-an`;
                  const capped = capitalize(action);

                  setConfirmDialogProps({
                    actionProceedText: capped,
                    content,
                    onProceedAppend: () => {
                      setConfirmDialogLoading(true);

                      api
                        .put(`/command/${command}/${anvilUuid}`)
                        .then(() => {
                          finishConfirm('Success', {
                            children: <>Successfully registered power job.</>,
                          });
                        })
                        .catch((error) => {
                          const emsg = handleAPIError(error);

                          emsg.children = (
                            <>Failed to register power job. {emsg.children}</>
                          );

                          finishConfirm('Error', emsg);
                        });
                    },
                    proceedColour,
                    titleText: `${capped} ${anvilName}?`,
                  });

                  setConfirmDialogOpen(true);
                }}
              />
            </Box>
          </>
        )}
      </StyledBox>
      {confirmDialog}
    </>
  );
};

export default SelectedAnvil;
