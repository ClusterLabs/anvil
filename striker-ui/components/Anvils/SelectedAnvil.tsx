import { Box as MuiBox, styled, Switch as MuiSwitch } from '@mui/material';
import { capitalize } from 'lodash';
import { useContext, useMemo } from 'react';

import anvilState from '../../lib/consts/ANVILS';

import api from '../../lib/api';
import { AnvilContext } from '../AnvilContext';
import Decorator, { Colours } from '../Decorator';
import handleAPIError from '../../lib/handleAPIError';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
import useConfirmDialog from '../../hooks/useConfirmDialog';

const PREFIX = 'SelectedAnvil';

const classes = {
  anvilName: `${PREFIX}-anvilName`,
};

const StyledBox = styled(MuiBox)(() => ({
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

const SelectedAnvil: React.FC<{
  list: AnvilListItem[];
}> = (props) => {
  const { list } = props;

  const { uuid } = useContext(AnvilContext);

  const index = useMemo(
    () => list.findIndex((li) => li.anvil_uuid === uuid),
    [list, uuid],
  );

  const li: AnvilListItem | undefined = list[index];

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog();

  if (!li) {
    return <Spinner />;
  }

  return (
    <>
      <StyledBox>
        <MuiBox p={1}>
          <Decorator colour={selectDecorator(li.anvilStatus.system)} />
        </MuiBox>
        <MuiBox p={1} flexGrow={1} className={classes.anvilName}>
          <HeaderText text={li.anvil_name} />
          <HeaderText
            text={anvilState.get(li.anvilStatus.system) ?? 'State unavailable'}
          />
        </MuiBox>
        <MuiBox p={1}>
          <MuiSwitch
            checked={isAnvilOn(li)}
            onChange={() => {
              const { [index]: litem } = list;
              const { anvil_name: anvilName, anvil_uuid: anvilUuid } = litem;

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
        </MuiBox>
      </StyledBox>
      {confirmDialog}
    </>
  );
};

export default SelectedAnvil;
