declare type AnvilListItem = {
  anvil_name: string;
  anvil_uuid: string;
} & AnvilStatus;

declare type AnvilList = {
  anvils: Array<AnvilListItem>;
};
