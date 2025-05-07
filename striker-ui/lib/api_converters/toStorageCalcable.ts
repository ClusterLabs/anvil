const toStorageCalcable = <
  T extends {
    free: string;
    size: string;
    used?: string;
  },
>(
  storage: T,
): Omit<T, 'free' | 'size' | 'used'> & {
  free: bigint;
  size: bigint;
  used: bigint;
} => {
  const { free: sFree, size: sSize, used: sUsed, ...rest } = storage;

  let free = BigInt(0);
  let size = BigInt(0);
  let used = BigInt(0);

  try {
    free = BigInt(sFree);
    size = BigInt(sSize);

    if (sUsed) {
      used = BigInt(sUsed);
    } else {
      used = size - free;
    }
  } catch (error) {
    // Ignore and use defaults.
  }

  return {
    ...rest,
    free,
    size,
    used,
  };
};

export default toStorageCalcable;
