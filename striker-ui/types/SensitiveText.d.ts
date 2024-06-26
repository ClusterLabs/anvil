type SensitiveTextWrapper = 'body' | 'mono' | 'none' | 'small';

type SensitiveTextOptionalProps = {
  revealInitially?: boolean;
  wrapper?: SensitiveTextWrapper;
  wrapperProps?: import('../components/Text').BodyTextProps;
};

type SensitiveTextProps = SensitiveTextOptionalProps;
