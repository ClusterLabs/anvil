import { dSize, dSizeStr } from 'format-data-size';
import * as yup from 'yup';

const nMin = BigInt(0);

/* eslint-disable no-template-curly-in-string */

const buildMemorySchema = (memory: AnvilMemoryCalcable) => {
  const { available: nMax } = memory;

  return yup.object({
    size: yup
      .string()
      .ensure()
      .test({
        exclusive: true,
        message: '${path} must be greater than or equal to ${min}',
        name: 'min',
        params: { min: String(nMin) },
        test: (value, context) => {
          let nValue: bigint;

          try {
            nValue = BigInt(value);
          } catch (error) {
            return context.createError({
              message: '${path} must be a valid integer',
            });
          }

          return nValue >= nMin;
        },
      })
      .test({
        exclusive: true,
        name: 'max',
        test: (value, context) => {
          const { unit } = context.parent;

          const current = dSize(value, {
            fromUnit: unit,
            precision: 0,
            toUnit: 'B',
          });

          if (!current) {
            return context.createError({
              message: '${path} is not a valid data size',
            });
          }

          const max = dSizeStr(nMax, { toUnit: unit }) ?? 'available memory';

          return (
            BigInt(current.value) <= nMax ||
            context.createError({
              message: '${path} must be less than or equal to ${max}',
              params: { max },
            })
          );
        },
      }),
    unit: yup.string().required(),
  });
};

export default buildMemorySchema;
