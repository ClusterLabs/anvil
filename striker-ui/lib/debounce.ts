import { debounce as baseDebounce } from 'lodash';

/* eslint-disable @typescript-eslint/no-explicit-any */

type BaseDebounce<Fn extends (...args: any) => any> = typeof baseDebounce<Fn>;

const debounce = <Fn extends (...args: any) => any>(
  fn: Fn,
  options: {
    wait?: Parameters<BaseDebounce<Fn>>[1];
  } & Parameters<BaseDebounce<Fn>>[2] = {},
): ReturnType<BaseDebounce<Fn>> => {
  const { wait = 500, ...rest } = options;

  return baseDebounce<Fn>(fn, wait, rest);
};

export default debounce;
