const before = (time: number, limit: number): boolean => {
  const diff = time - limit;

  return diff > 0;
};

const last = (
  time: number,
  duration: number,
  { ms }: { ms?: boolean } = {},
): boolean => {
  let now = Date.now();

  if (!ms) {
    now /= 1000;
  }

  const diff = now - time;

  return diff <= duration;
};

export { before, last };
