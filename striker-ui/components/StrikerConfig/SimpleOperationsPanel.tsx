import { Grid } from '@mui/material';
import { FC } from 'react';
import ContainedButton, { ContainedButtonProps } from '../ContainedButton';
import { Panel, PanelHeader } from '../Panels';
import { HeaderText } from '../Text';

type SimpleOperationsPanelProps = {
  strikerHostName: string;
};

const StretchedButton: FC<ContainedButtonProps> = (props) => (
  <ContainedButton {...props} sx={{ width: '100%' }} />
);

const SimpleOperationsPanel: FC<SimpleOperationsPanelProps> = ({
  strikerHostName,
}) => (
  <Panel>
    <PanelHeader>
      <HeaderText text={strikerHostName} />
    </PanelHeader>
    <Grid columns={{ xs: 1, sm: 2 }} container spacing="1em">
      <Grid item sm={2} xs={1}>
        <StretchedButton>Update system</StretchedButton>
      </Grid>
      <Grid item sm={2} xs={1}>
        <StretchedButton>Enable &quot;Install target&quot;</StretchedButton>
      </Grid>
      <Grid item xs={1}>
        <StretchedButton>Reboot</StretchedButton>
      </Grid>
      <Grid item xs={1}>
        <StretchedButton>Shutdown</StretchedButton>
      </Grid>
    </Grid>
  </Panel>
);

export default SimpleOperationsPanel;
