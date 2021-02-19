import { FunctionComponent } from 'react';
import Image from 'next/image';
import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

const StyledHeader = styled.div`
  display: flex;

  justify-content: space-between;
  align-content: center;

  padding: 0.5em 1.5em;

  border-style: solid;
  border-color: #d02724;

  border-width: 0 0 1px 0;
`;

const StyledRightContainer = styled.div`
  display: flex;

  > * {
    padding: 0 0 0 0.5em;
  }
`;

StyledHeader.defaultProps = {
  theme: DEFAULT_THEME,
};

const Header: FunctionComponent = () => {
  return (
    <StyledHeader>
      <div>
        <Image src="/pngs/logo.png" width="160" height="40" />
      </div>
      <StyledRightContainer>
        <div>
          <Image src="/pngs/files_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/tasks_no-jobs_icon.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/configure_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/striker_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/anvil_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/email_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/users_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/help_icon_on.png" width="40" height="40" />
        </div>
      </StyledRightContainer>
    </StyledHeader>
  );
};

export default Header;
