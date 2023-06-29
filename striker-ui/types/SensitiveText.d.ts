type SensitiveTextOptionalProps = {
  inline?: boolean;
  monospaced?: boolean;
  revealButtonProps?: import('../components/IconButton').IconButtonProps;
  revealInitially?: boolean;
  textLineHeight?: number | null;
  textProps?: import('../components/Text').BodyTextProps;
};

type SensitiveTextProps = SensitiveTextOptionalProps;
