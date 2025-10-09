/**
 * Un-does `x = 2 ^ n` without logs.
 *
 * @param value - `x`
 *
 * @returns `n`
 */
export const un2n = (value: number): number => {
  let x = value;
  let n = 0;

  while (x > 0) {
    x >>= 1;
    n += 1;
  }

  return n;
};
