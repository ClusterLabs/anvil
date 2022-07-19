import { FC, useState } from 'react';
import { Box as MUIBox } from '@mui/material';

import NetworkInitForm from './NetworkInitForm';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import { HeaderText } from './Text';

const StrikerInitForm: FC = () => {
  const [organizationNameInput, setOrganizationNameInput] =
    useState<string>('');

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Initialize striker" />
      </PanelHeader>
      <MUIBox
        sx={{
          display: 'flex',
          flexDirection: 'column',

          '& > :not(:first-child)': { marginTop: '1em' },
        }}
      >
        <OutlinedInputWithLabel
          label="Organization name"
          onChange={({ target: { value } }) => {
            setOrganizationNameInput(String(value));
          }}
          value={organizationNameInput}
        />
        <OutlinedInputWithLabel label="Organization prefix" />
        <OutlinedInputWithLabel label="Domain name" />
        <OutlinedInputWithLabel label="Striker number" />
        <NetworkInitForm />
      </MUIBox>
    </Panel>
  );
};

export default StrikerInitForm;
