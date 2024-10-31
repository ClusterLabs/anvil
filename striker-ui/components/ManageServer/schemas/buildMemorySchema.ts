import { dSize, dSizeStr } from 'format-data-size';
import * as yup from 'yup';

// Unit: bytes; 64 KiB
const nMin = BigInt(65536);

const nds = 'not-data-size';

/* eslint-disable no-template-curly-in-string */

const buildMemorySchema = (memory: AnvilMemoryCalcable) => {
  const { available: nMax } = memory;

  return yup.object({
    size: yup
      .string()
      .required()
      .when(['unit'], (values, schema) => {
        const [unit] = values;

        return schema.transform((value) => {
          if (unit === 'B') return value;

          const current = dSize(value, {
            fromUnit: unit,
            precision: 0,
            toUnit: 'B',
          });

          return current ? current.value : nds;
        });
      })
      .test({
        exclusive: true,
        message: '${path} is not a valid data size',
        name: 'datasize',
        test: (value) => value !== nds,
      })
      .test({
        exclusive: true,
        name: 'sequence',
        test: (value, { createError, parent }) => {
          let nValue: bigint;

          try {
            nValue = BigInt(value);
          } catch (error) {
            return createError({
              message: '${path} cannot have decimal bytes',
            });
          }

          if (!(nValue >= nMin)) {
            return createError({
              message: '${path} must be greater than or equal to ${min}',
              params: { min: `${nMin} B` },
            });
          }

          const max =
            dSizeStr(nMax, {
              toUnit: parent.unit,
            }) ?? 'available memory';

          if (!(nValue <= nMax)) {
            return createError({
              message: '${path} must be less than or equal to ${max}',
              params: { max },
            });
          }

          return true;
        },
      }),
    unit: yup.string().required(),
  });
};

export default buildMemorySchema;
