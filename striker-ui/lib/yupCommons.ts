import { DataSizeUnit, dSize, dSizeStr } from 'format-data-size';
import * as yup from 'yup';

import { REP_IPV4, REP_MAC, REP_UUID } from './consts/REG_EXP_PATTERNS';

/**
 * This is OK because yup uses the template string syntax internally to access
 * the field name.
 */
/* eslint-disable no-template-curly-in-string */

export const yupLaxMac = () =>
  yup.string().matches(REP_MAC, {
    message: '${path} must be a valid MAC address',
  });

export const yupLaxUuid = () =>
  yup.string().matches(REP_UUID, {
    message: '${path} must be a valid UUID',
  });

export const yupIpv4 = () =>
  yup.string().matches(REP_IPV4, {
    message: '${path} must be a valid IPv4 address',
  });

export const yupDataSize = (options: {
  baseUnit?: DataSizeUnit;
  max?: bigint;
  min?: bigint;
  nds?: string;
}) => {
  const {
    baseUnit = 'B',
    max: nMax,
    min: nMin,
    nds = 'not-data-size',
  } = options;

  let testMax: yup.TestFunction<bigint>;
  let testMin: yup.TestFunction<bigint>;

  if (nMin) {
    testMin = (nValue, context) => {
      const { createError } = context;

      const min =
        dSizeStr(nMin, {
          toUnit: 'ibyte',
        }) ?? `${nMin} ${baseUnit}`;

      if (!(nValue >= nMin)) {
        throw createError({
          message: '${path} must be greater than or equal to ${min}',
          params: { min },
        });
      }

      return true;
    };
  }

  if (nMax) {
    testMax = (nValue, context) => {
      const { createError, parent } = context;

      const max =
        dSizeStr(nMax, {
          toUnit: parent.unit,
        }) ?? 'available size';

      if (!(nValue <= nMax)) {
        throw createError({
          message: '${path} must be less than or equal to ${max}',
          params: { max },
        });
      }

      return true;
    };
  }

  return yup.object({
    value: yup
      .string()
      .ensure()
      .when(['unit'], (values, schema) => {
        const [unit] = values;

        if (/percent/.test(unit)) {
          return schema.test({
            exclusive: true,
            name: 'percent',
            test: (value, context) => {
              const { createError } = context;

              const n = Number(value);

              if (!Number.isSafeInteger(n)) {
                return createError({
                  message: '${path} (%) must be a valid integer',
                });
              }

              const max = 100;
              const min = 0;

              if (!(n <= max)) {
                return createError({
                  message: '${path} (%) must be less than or equal to ${max}%',
                  params: { max },
                });
              }

              if (!(n >= min)) {
                return createError({
                  message:
                    '${path} (%) must be greater than or equal to ${min}%',
                  params: { min },
                });
              }

              return true;
            },
          });
        }

        return schema
          .transform((value) => {
            if (unit === baseUnit) return value;

            const current = dSize(value, {
              fromUnit: unit,
              precision: 0,
              toUnit: baseUnit,
            });

            return current ? current.value : nds;
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
            test: (value, context) => {
              const { createError } = context;

              let nValue: bigint;

              try {
                nValue = BigInt(value);
              } catch (error) {
                return createError({
                  message: '${path} cannot have decimal bytes',
                });
              }

              try {
                testMin?.call(context, nValue, context);
                testMax?.call(context, nValue, context);
              } catch (error) {
                return error as yup.ValidationError;
              }

              return true;
            },
          });
      }),
    unit: yup.string(),
  });
};
