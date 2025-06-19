import { useEffect, useMemo, useState } from 'react';

import { BLACK } from '../../lib/consts/DEFAULT_THEME';

import CommonUpsInputGroup, {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
} from './CommonUpsInputGroup';
import FlexBox from '../FlexBox';
import Link from '../Link';
import SelectWithLabel from '../SelectWithLabel';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import useIsFirstRender from '../../hooks/useIsFirstRender';

const INPUT_ID_UPS_TYPE = 'add-ups-select-ups-type-id';

const INPUT_LABEL_UPS_TYPE = 'UPS type';

const AddUpsInputGroup = <
  M extends {
    [K in
      | typeof INPUT_ID_UPS_IP
      | typeof INPUT_ID_UPS_NAME
      | typeof INPUT_ID_UPS_TYPE]: string;
  },
>(
  ...[props]: Parameters<React.FC<AddUpsInputGroupProps<M>>>
): ReturnType<React.FC<AddUpsInputGroupProps<M>>> => {
  const {
    formUtils,
    loading: isExternalLoading,
    previous = {},
    upsTemplate,
  } = props;

  const { buildInputFirstRenderFunction, setValidity } = formUtils;

  const { upsTypeId: previousUpsTypeId = '' } = previous;

  const isFirstRender = useIsFirstRender();

  const [inputUpsTypeIdValue, setInputUpsTypeIdValue] =
    useState<string>(previousUpsTypeId);

  const upsTypeOptions = useMemo<SelectItem[]>(
    () =>
      Object.entries(upsTemplate).map<SelectItem>(
        ([
          upsTypeId,
          {
            brand,
            description,
            links: { 0: link },
          },
        ]) => {
          let linkElement: React.ReactNode;

          if (link) {
            const { linkHref, linkLabel } = link;

            linkElement = (
              <Link
                href={linkHref}
                onClick={(event) => {
                  // Don't trigger the (parent) item selection event.
                  event.stopPropagation();
                }}
                sx={{ display: 'inline-flex', color: BLACK }}
                target="_blank"
              >
                {linkLabel}
              </Link>
            );
          }

          return {
            displayValue: (
              <FlexBox spacing={0}>
                <BodyText inverted>{brand}</BodyText>
                <BodyText inverted>
                  {description} ({linkElement})
                </BodyText>
              </FlexBox>
            ),
            value: upsTypeId,
          };
        },
      ),
    [upsTemplate],
  );

  useEffect(() => {
    if (isFirstRender) {
      buildInputFirstRenderFunction(INPUT_ID_UPS_TYPE)({
        isValid: Boolean(inputUpsTypeIdValue),
      });
    }
  }, [buildInputFirstRenderFunction, inputUpsTypeIdValue, isFirstRender]);

  if (isExternalLoading) {
    return <Spinner />;
  }

  return (
    <FlexBox>
      <SelectWithLabel
        formControlProps={{ sx: { marginTop: '.3em' } }}
        id={INPUT_ID_UPS_TYPE}
        label={INPUT_LABEL_UPS_TYPE}
        onChange={({ target: { value: rawNewValue } }) => {
          const newValue = String(rawNewValue);

          setValidity(INPUT_ID_UPS_TYPE, true);
          setInputUpsTypeIdValue(newValue);
        }}
        required
        selectItems={upsTypeOptions}
        selectProps={{
          onClearIndicatorClick: () => {
            setValidity(INPUT_ID_UPS_TYPE, false);
            setInputUpsTypeIdValue('');
          },
          renderValue: (rawValue) => {
            const upsTypeId = String(rawValue);
            const { brand } = upsTemplate[upsTypeId];

            return brand;
          },
        }}
        value={inputUpsTypeIdValue}
      />
      {inputUpsTypeIdValue && (
        <CommonUpsInputGroup formUtils={formUtils} previous={previous} />
      )}
    </FlexBox>
  );
};

export { INPUT_ID_UPS_TYPE, INPUT_LABEL_UPS_TYPE };

export default AddUpsInputGroup;
