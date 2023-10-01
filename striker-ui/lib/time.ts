const before = (time: number, limit: number): boolean => {
  const diff = time - limit;

  return diff > 0;
};

const now = (ms?: boolean): number => {
  let nao = Date.now();

  if (!ms) nao = Math.floor(nao / 1000);

  return nao;
};

const last = (
  time: number,
  duration: number,
  { ms }: { ms?: boolean } = {},
): boolean => {
  const diff = now(ms) - time;

  return diff <= duration;
};

const elapsed = (
  duration: number,
): { h: number; m: number; s: number; unit: string; value: number } => {
  let src = duration;

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
  ].find(({ value }) => value) ?? { unit: 's', value: s };

  return {
    h,
    m,
    s,
    ...significant,
  };
};

export { before, elapsed, last, now };
