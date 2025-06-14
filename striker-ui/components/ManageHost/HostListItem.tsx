import Decorator, { Colours } from '../Decorator';
import Divider from '../Divider';
import FlexBox from '../FlexBox';
import { BodyText, MonoText } from '../Text';

const MAP_TO_DECORATOR_COLOUR: Record<string, Colours> = {
  online: 'ok',
  offline: 'off',
};

const MAP_TO_HOST_TYPE_DISPLAY: Record<string, string> = {
  dr: 'DR',
  node: 'Subnode',
};

const HostListItem: React.FC<HostListItemProps> = (props) => {
  const { data } = props;

  const { hostName, hostStatus, hostType, shortHostName } = data;

  return (
    <FlexBox row spacing=".5em">
      <Decorator
        colour={MAP_TO_DECORATOR_COLOUR[hostStatus] ?? 'warning'}
        sx={{
          alignSelf: 'stretch',
          height: 'auto',
        }}
      />
      <FlexBox flexGrow={1} spacing={0}>
        <FlexBox sm="row" spacing=".5em">
          <BodyText>{MAP_TO_HOST_TYPE_DISPLAY[hostType]}</BodyText>
          <MonoText whiteSpace="nowrap">{shortHostName}</MonoText>
          <Divider
            orientation="vertical"
            sx={{
              alignSelf: 'stretch',
              height: 'auto',
            }}
          />
          <MonoText
            sx={{ display: { xs: 'none', sm: 'flex' } }}
            whiteSpace="nowrap"
          >
            {hostName}
          </MonoText>
        </FlexBox>
        <BodyText>{hostStatus}</BodyText>
      </FlexBox>
    </FlexBox>
  );
};

export default HostListItem;
