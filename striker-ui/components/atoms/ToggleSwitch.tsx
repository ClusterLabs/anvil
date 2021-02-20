import { FunctionComponent, useEffect, useState } from 'react';
import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

import { ToggleSwitchProps } from '../../types/ToggleSwitchProps';

const StyledCheckbox = styled.input`
  display: none;
`;

const StyledToggleSwitchBase = styled.div<ToggleSwitchProps>`
  display: flex;

  align-items: center;

  width: 3em;
  height: 1.5em;

  transition-property: background-color, border-color;
  transition-duration: 1s;

  background-color: ${(props) =>
    props.checked ? '#d02724' : props.theme.colors.tertiary};

  border-style: solid;
  border-width: 0.2em;

  border-color: ${(props) =>
    props.checked ? '#d02724' : props.theme.colors.tertiary};

  > * {
    flex-basis: 45%;
    height: 100%;
  }
`;

const StyledToggleSwitchLever = styled.div<ToggleSwitchProps>`
  background-color: ${(props) => props.theme.colors.primary};

  transition: margin-left 1s;

  margin-left: ${(props) => (props.checked ? '55%' : '0')};
`;

StyledCheckbox.defaultProps = {
  theme: DEFAULT_THEME,
};

StyledToggleSwitchBase.defaultProps = {
  theme: DEFAULT_THEME,
};

StyledToggleSwitchLever.defaultProps = {
  theme: DEFAULT_THEME,
};

const ToggleSwitch: FunctionComponent<ToggleSwitchProps> = ({
  checked = false,
  disabled,
}) => {
  const [on, setOn] = useState<boolean>(checked);

  // Update the toggle switch when supplied props change
  useEffect(() => {
    setOn(checked);
  }, [checked]);

  return (
    <StyledToggleSwitchBase
      {...{
        onClick: () => {
          setOn(!on);
        },
        checked: on,
      }}
    >
      <StyledToggleSwitchLever {...{ checked: on }} />
      <StyledCheckbox
        {...{ checked: on, disabled, readOnly: true, type: 'checkbox' }}
      />
    </StyledToggleSwitchBase>
  );
};

export default ToggleSwitch;
