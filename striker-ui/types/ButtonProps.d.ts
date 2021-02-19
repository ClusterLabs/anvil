import { LinkProps } from 'next/link';

import { ButtonImageProps } from './ButtonImageProps';

type ButtonProps = {
  imageProps?: ButtonImageProps;
  isSubmit?: boolean;
  labelProps?: LabelProps;
  linkProps?: LinkProps;
};
