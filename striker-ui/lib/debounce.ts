import base from 'lodash/debounce';

/* eslint-disable @typescript-eslint/no-explicit-any */

type BaseDebounce<Fn extends (...args: any) => any> = typeof base<Fn>;

const debounce = <Fn extends (...args: any) => any>(
  fn: Fn,
  options: {
    wait?: Parameters<BaseDebounce<Fn>>[1];
  } & Parameters<BaseDebounce<Fn>>[2] = {},
): ReturnType<BaseDebounce<Fn>> => {
  const { wait = 500, ...rest } = options;

  return base<Fn>(fn, wait, rest);
};

export default debounce;
