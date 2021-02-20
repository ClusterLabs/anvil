import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

const PageContainer = styled.div`
  min-height: 100vh;
  width: 100vw;

  background-color: ${(props) => props.theme.colors.secondary};
`;

PageContainer.defaultProps = {
  theme: DEFAULT_THEME,
};

export default PageContainer;
