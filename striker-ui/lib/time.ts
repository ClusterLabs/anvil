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

const elapsed = (
  duration: number,
  { ms }: { ms?: boolean } = {},
): { h: number; m: number; s: number; unit: string; value: number } => {
  let src = duration;

  if (!ms) {
    src /= 1000;
  }

  const parts = [60, 60].reduce<number[]>((previous, multiplier) => {
    const remainder = src % multiplier;

    previous.push(remainder);

    src = (src - remainder) / multiplier;

    return previous;
  }, []);

  const [s, m, h] = [...parts, src];

  const significant = [
    { unit: 'h', value: h },
    { unit: 'm', value: m },
  ].reduce(
    (previous, current) => {
      const { value } = current;

      return value ? current : previous;
    },
    { unit: 's', value: s },
  );

  return {
    h,
    m,
    s,
    ...significant,
  };
};

export { before, elapsed, last };
