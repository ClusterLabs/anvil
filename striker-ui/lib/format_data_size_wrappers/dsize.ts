import {
  DataSizeUnit,
  formatDataSize,
  FormatDataSizeInputValue,
  FormatDataSizeOptions,
} from 'format-data-size';

const dsize = (
  valueToFormat: FormatDataSizeInputValue,
  {
    fromUnit,
    onFailure,
    onSuccess,
    precision,
    toUnit,
  }: FormatDataSizeOptions & {
    onFailure?: (error?: unknown, value?: string, unit?: DataSizeUnit) => void;
    onSuccess?: {
      bigint?: (value: bigint, unit: DataSizeUnit) => void;
      number?: (value: number, unit: DataSizeUnit) => void;
      string?: (value: string, unit: DataSizeUnit) => void;
    };
  } = {},
): void => {
  const formatted = formatDataSize(valueToFormat, {
    fromUnit,
    precision,
    toUnit,
  });

  if (formatted) {
    const { value, unit } = formatted;

    try {
      onSuccess?.bigint?.call(null, BigInt(value), unit);
      onSuccess?.number?.call(null, parseFloat(value), unit);
      onSuccess?.string?.call(null, value, unit);
    } catch (convertValueToTypeError) {
      onFailure?.call(null, convertValueToTypeError, value, unit);
    }
  } else {
    onFailure?.call(null);
  }
};

export default dsize;
