import { DataSizeUnit, FormatDataSizeInputValue } from 'format-data-size';

import dsize from './dsize';

const dsizeToByte = (
  value: FormatDataSizeInputValue,
  fromUnit: DataSizeUnit,
  onSuccess: (newValue: bigint, unit: DataSizeUnit) => void,
  onFailure?: (
    error?: unknown,
    unchangedValue?: string,
    unit?: DataSizeUnit,
  ) => void,
): void => {
  dsize(value, {
    fromUnit,
    onFailure,
    onSuccess: {
      bigint: onSuccess,
    },
    precision: 0,
    toUnit: 'B',
  });
};

export default dsizeToByte;
