import { FunctionComponent } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

import { ButtonImageProps } from '../../types/ButtonImageProps';
import { ButtonProps } from '../../types/ButtonProps';
import Label from './Label';

const DEFAULT_BUTTON_IMAGE_SIZE = 30;

const StyledButton = styled.button`
  display: flex;

  flex-direction: row;
  flex-wrap: nowrap;
`;

const StyledSeparator = styled.div`
  margin-right: 0.5em;
`;

StyledButton.defaultProps = {
  theme: DEFAULT_THEME,
};

const getButtonImageElement: (
  imageProps?: ButtonImageProps,
) => JSX.Element | undefined = (imageProps) => {
  let imageElement: JSX.Element | undefined;

  if (imageProps) {
    const {
      src,
      width = DEFAULT_BUTTON_IMAGE_SIZE,
      height = DEFAULT_BUTTON_IMAGE_SIZE,
    } = imageProps;

    imageElement = <Image {...{ src, width, height }} />;
  }

  return imageElement;
};

const getButtonLabelElement: (
  labelProps?: LabelProps,
) => JSX.Element | undefined = (labelProps) => {
  let labelElement: JSX.Element | undefined;

  if (labelProps) {
    const { text } = labelProps;

    labelElement = <Label {...{ text }} />;
  }

  return labelElement;
};

const Button: FunctionComponent<ButtonProps> = ({
  imageProps,
  isSubmit,
  labelProps,
  linkProps,
  onClick,
}) => {
  const imageElement: JSX.Element | undefined = getButtonImageElement(
    imageProps,
  );

  const labelElement: JSX.Element | undefined = getButtonLabelElement(
    labelProps,
  );

  const separatorElement: JSX.Element | undefined =
    imageElement && labelElement ? <StyledSeparator /> : undefined;

  let resultElement: JSX.Element;

  if (linkProps) {
    const { href, passHref = true } = linkProps;

    resultElement = (
      <Link {...{ href, passHref }}>
        <StyledButton as="a">
          {imageElement}
          {separatorElement}
          {labelElement}
        </StyledButton>
      </Link>
    );
  } else {
    resultElement = (
      <StyledButton type={isSubmit ? 'submit' : 'button'} {...{ onClick }}>
        {imageElement}
        {separatorElement}
        {labelElement}
      </StyledButton>
    );
  }

  return resultElement;
};

export default Button;
