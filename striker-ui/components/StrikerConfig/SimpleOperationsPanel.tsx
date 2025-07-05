import Grid from '@mui/material/Grid';
import MuiSwitch from '@mui/material/Switch';
import { useMemo, useState } from 'react';

import api from '../../lib/api';
import ContainedButton from '../ContainedButton';
import FlexBox from '../FlexBox';
import handleAPIError from '../../lib/handleAPIError';
import MessageBox, { Message } from '../MessageBox';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';

const StretchedButton: React.FC<ContainedButtonProps> = (props) => (
  <ContainedButton {...props} sx={{ width: '100%' }} />
);

const SimpleOperationsPanel: React.FC<SimpleOperationsPanelProps> = ({
  installTarget = 'disabled',
  onSubmit,
  title,
}) => {
  const [message, setMessage] = useState<Message | undefined>();

  const headerElement = useMemo(
    () =>
      title ? (
        <HeaderText sx={{ textAlign: 'center' }}>{title}</HeaderText>
      ) : (
        <Spinner mt={0} />
      ),
    [title],
  );
  const messageElement = useMemo(
    () =>
      message && (
        <Grid item sm={2} xs={1}>
          <MessageBox
            {...message}
            onClose={() => {
              setMessage(undefined);
            }}
          />
        </Grid>
      ),
    [message, setMessage],
  );

  return (
    <Panel>
      <PanelHeader>{headerElement}</PanelHeader>
      <Grid columns={{ xs: 1, sm: 2 }} container spacing="1em">
        <Grid
          // Hide the install target switch until it's ready.
          display="none"
          item
          sm={2}
          xs={1}
        >
          <FlexBox row>
            <BodyText sx={{ flexGrow: 1 }}>Install target</BodyText>
            <MuiSwitch
              checked={installTarget === 'enabled'}
              edge="end"
              onChange={(event, isChecked) => {
                let actionText = 'disable';
                let actionTextCap = 'Disable';

                if (isChecked) {
                  actionText = 'enable';
                  actionTextCap = 'Enable';
                }

                onSubmit?.call(null, {
                  actionProceedText: actionTextCap,
                  content: (
                    <BodyText>
                      Would you like to {actionText} &quot;Install target&quot;
                      on this striker? It&apos;ll take a few moments to
                      complete.
                    </BodyText>
                  ),
                  onProceedAppend: () => {
                    api
                      .put(
                        '/host/local',
                        { isEnableInstallTarget: isChecked },
                        { params: { handler: 'install-target' } },
                      )
                      .catch((error) => {
                        const emsg = handleAPIError(error);

                        emsg.children = `Failed to ${actionText} "Install target". ${emsg.children}`;

                        setMessage(emsg);
                      });
                  },
                  titleText: `${actionTextCap} "Install target" on ${title}?`,
                });
              }}
            />
          </FlexBox>
        </Grid>
        <Grid item sm={2} xs={1}>
          <StretchedButton
            onClick={() => {
              onSubmit?.call(null, {
                actionProceedText: 'Update',
                content: (
                  <BodyText>
                    Would you like to update the operating system on this
                    striker? It&apos;ll be placed into maintenance mode until
                    the update completes.
                  </BodyText>
                ),
                onProceedAppend: () => {
                  api.put('/command/update-system').catch((error) => {
                    const emsg = handleAPIError(error);

                    emsg.children = `Failed to initiate system update. ${emsg.children}`;

                    setMessage(emsg);
                  });
                },
                titleText: `Update operating system on ${title}?`,
              });
            }}
          >
            Update system
          </StretchedButton>
        </Grid>
        <Grid item sm={2} xs={1}>
          <StretchedButton href="/init?re=1">
            Reconfigure striker
          </StretchedButton>
        </Grid>
        <Grid item xs={1}>
          <StretchedButton
            onClick={() => {
              onSubmit?.call(null, {
                actionProceedText: 'Reboot',
                content: (
                  <BodyText>Would you like to reboot this striker?</BodyText>
                ),
                onProceedAppend: () => {
                  api.put('/command/reboot-host').catch((error) => {
                    const emsg = handleAPIError(error);

                    emsg.children = `Failed to initiate system reboot. ${emsg.children}`;

                    setMessage(emsg);
                  });
                },
                titleText: `Reboot ${title}?`,
              });
            }}
          >
            Reboot
          </StretchedButton>
        </Grid>
        <Grid item xs={1}>
          <StretchedButton
            onClick={() => {
              onSubmit?.call(null, {
                actionProceedText: 'Shutdown',
                content: (
                  <BodyText>Would you like to shutdown this striker?</BodyText>
                ),
                onProceedAppend: () => {
                  api.put('/command/poweroff-host').catch((error) => {
                    const emsg = handleAPIError(error);

                    emsg.children = `Failed to initiate system shutdown. ${emsg.children}`;

                    setMessage(emsg);
                  });
                },
                titleText: `Shutdown ${title}?`,
              });
            }}
          >
            Shutdown
          </StretchedButton>
        </Grid>
        {messageElement}
      </Grid>
    </Panel>
  );
};

export default SimpleOperationsPanel;
