type StackBarValue = {
  colour?: string | Record<number, string>;
  value: number;
};

type StackBarProps = {
  value: StackBarValue | Record<string, StackBarValue>;
};
