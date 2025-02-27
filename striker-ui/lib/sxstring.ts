import { createElement } from 'react';

/**
 * "jsx"/"tsx" + "string"; wraps input with wrapper if input is a string.
 */
const sxstring = <Props extends object>(
  children: React.ReactNode,
  wrapper:
    | React.FunctionComponent<Props>
    | React.ComponentClass<Props>
    | string,
  props?: (React.Attributes & Props) | null | undefined,
): React.ReactNode =>
  typeof children === 'string'
    ? createElement(wrapper, props, children)
    : children;

export default sxstring;
