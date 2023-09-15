import { ReactNode, createElement } from 'react';

/**
 * "jsx"/"tsx" + "string"; wraps input with wrapper if input is a string.
 */
const sxstring = (
  children: ReactNode,
  wrapper: CreatableComponent,
): ReactNode =>
  typeof children === 'string'
    ? createElement(wrapper, null, children)
    : children;

export default sxstring;
