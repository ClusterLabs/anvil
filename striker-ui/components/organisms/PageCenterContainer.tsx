import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

const PageCenterContainer = styled.div`
  width: 50%;

  padding-top: 1em;

  margin-left: auto;
  margin-right: auto;

  > :not(:first-child) {
    margin-top: 1em;
  }
`;

PageCenterContainer.defaultProps = {
  theme: DEFAULT_THEME,
};

export default PageCenterContainer;
