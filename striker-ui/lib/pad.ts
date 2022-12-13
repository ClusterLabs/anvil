const pad = (
  value: unknown,
  {
    fillString = '0',
    maxLength = 2,
    which = 'Start',
  }: {
    fillString?: string;
    maxLength?: number;
    which?: 'Start' | 'End';
  } = {},
): string => String(value)[`pad${which}`](maxLength, fillString);

export default pad;
