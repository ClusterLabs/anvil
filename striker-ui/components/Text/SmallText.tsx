import BodyText, { BodyTextProps } from './BodyText';

const SmallText: React.FC<BodyTextProps> = (props) => (
  <BodyText variant="body2" {...props} />
);

export default SmallText;
