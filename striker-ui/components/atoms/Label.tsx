import { FunctionComponent } from 'react';
import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

type LabelProps = {
  text: string;
};

const StyledLabel = styled.span`
  font-size: 1em;
  color: ${(props) => props.theme.colors.primary};
`;

StyledLabel.defaultProps = {
  theme: DEFAULT_THEME,
};

const Label: FunctionComponent<LabelProps> = ({ text }) => {
  return <StyledLabel>{text}</StyledLabel>;
};

export default Label;
