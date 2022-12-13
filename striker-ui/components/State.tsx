import {
  Check as MUICheckIcon,
  Close as MUICloseIcon,
} from '@mui/icons-material';
import { cloneElement, createElement, FC, ReactElement } from 'react';

import { BLUE, PURPLE } from '../lib/consts/DEFAULT_THEME';

import FlexBox from './FlexBox';
import { BodyText, SmallText } from './Text';

type StateTypeMap = Pick<MapToType, 'boolean'>;

type StateMap<TypeName extends keyof StateTypeMap> = Map<
  StateTypeMap[TypeName],
  ReactElement
>;

type LabelMap = Record<'small' | 'medium', FC>;

type StateOptionalProps<TypeName extends keyof StateTypeMap> = {
  size?: keyof LabelMap;
  stateMap?: StateMap<TypeName>;
};

type StateProps<TypeName extends keyof StateTypeMap> =
  StateOptionalProps<TypeName> & {
    label: string;
    state: StateTypeMap[TypeName];
  };

const MAP_TO_TEXT_ELEMENT: LabelMap = {
  small: SmallText,
  medium: BodyText,
};

const STATE_DEFAULT_PROPS: Required<StateOptionalProps<'boolean'>> = {
  size: 'small',
  stateMap: new Map<boolean, ReactElement>([
    [false, <MUICloseIcon key="state-false" sx={{ color: PURPLE }} />],
    [true, <MUICheckIcon key="state-true" sx={{ color: BLUE }} />],
  ]),
};

const State = <TypeName extends keyof StateTypeMap>({
  label,
  size = STATE_DEFAULT_PROPS.size,
  state,
  stateMap = STATE_DEFAULT_PROPS.stateMap,
}: StateProps<TypeName>): ReturnType<FC<StateProps<TypeName>>> => {
  const stateIcon = stateMap.get(state);

  return (
    <FlexBox row spacing=".3em">
      {stateIcon && cloneElement(stateIcon, { fontSize: size })}
      {createElement(MAP_TO_TEXT_ELEMENT[size], {}, label)}
    </FlexBox>
  );
};

State.defaultProps = STATE_DEFAULT_PROPS;

export default State;
