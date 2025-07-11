import MuiArrowDownwardIcon from '@mui/icons-material/ArrowDownward';
import MuiArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import { BoxProps as MuiBoxProps } from '@mui/material/Box';
import { forwardRef, useImperativeHandle, useMemo, useState } from 'react';

import FlexBox from '../FlexBox';
import IconButton from '../IconButton';

type OrderControlBoxForwardedRefContent<O extends number | string> = {
  selectedId?: O;
  setSelectedId: (value?: O) => void;
};

/**
 * @prop {number} order - Array of IDs for ordering.
 */
type OrderFormikValues<O extends number | string> = {
  order: O[];
};

type OrderControlBoxProps<
  O extends number | string,
  V extends OrderFormikValues<O>,
> = {
  formikUtils: FormikUtils<V>;
  slotProps?: {
    box?: Partial<MuiBoxProps>;
  };
};

const OrderControlBox = forwardRef(
  <O extends number | string, V extends OrderFormikValues<O>>(
    props: OrderControlBoxProps<O, V>,
    ref: React.ForwardedRef<OrderControlBoxForwardedRefContent<O>>,
  ) => {
    const { formikUtils, slotProps } = props;

    const { formik } = formikUtils;

    const [selectedId, setSelectedId] = useState<O | undefined>();

    const chains = useMemo(
      () => ({
        order: `order`,
      }),
      [],
    );

    /**
     * Position of the selected ID in the order array.
     */
    const selectedRowPosition = useMemo<number>(() => {
      if (selectedId === undefined) {
        return -1;
      }

      return formik.values.order.indexOf(selectedId);
    }, [formik.values.order, selectedId]);

    const disableUp = useMemo<boolean>(() => {
      const index = selectedRowPosition;

      return index < 1;
    }, [selectedRowPosition]);

    const disableDown = useMemo<boolean>(() => {
      const index = selectedRowPosition;

      const last = formik.values.order.length - 1;

      return index < 0 || index >= last;
    }, [formik.values.order.length, selectedRowPosition]);

    useImperativeHandle(
      ref,
      () => ({
        selectedId,
        setSelectedId,
      }),
      [selectedId],
    );

    return (
      <FlexBox spacing=".6em" {...slotProps?.box}>
        <IconButton
          disabled={disableUp}
          onClick={() => {
            const { order } = formik.values;

            const indexA = selectedRowPosition;

            if (disableUp) return;

            const indexB = indexA - 1;

            // Swap [..., b, a, ...] in boot array.

            const { [indexB]: b, [indexA]: a } = order;

            const clone = [...order];

            clone.splice(indexB, 2, a, b);

            formik.setFieldValue(chains.order, clone, true);
          }}
        >
          <MuiArrowUpwardIcon fontSize="small" />
        </IconButton>
        <IconButton
          disabled={disableDown}
          onClick={() => {
            const { order } = formik.values;

            const indexA = selectedRowPosition;

            if (disableDown) return;

            const indexB = indexA + 1;

            // Swap [..., a, b, ...] in boot array.

            const { [indexA]: a, [indexB]: b } = order;

            const clone = [...order];

            clone.splice(indexA, 2, b, a);

            formik.setFieldValue(chains.order, clone, true);
          }}
        >
          <MuiArrowDownwardIcon fontSize="small" />
        </IconButton>
      </FlexBox>
    );
  },
);

OrderControlBox.displayName = 'ServerBootOrderControlBox';

export type {
  OrderControlBoxForwardedRefContent,
  OrderControlBoxProps,
  OrderFormikValues,
};

export default OrderControlBox as <
  O extends number | string,
  V extends OrderFormikValues<O>,
>(
  ...params: Parameters<
    React.FC<
      OrderControlBoxProps<O, V> &
        React.RefAttributes<OrderControlBoxForwardedRefContent<O>>
    >
  >
) => ReturnType<React.FC<OrderControlBoxProps<O, V>>>;
