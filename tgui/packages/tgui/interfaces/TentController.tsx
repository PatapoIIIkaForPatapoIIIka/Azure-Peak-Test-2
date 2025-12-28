import { Button, Section, LabeledList } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  owner_name: string;
  is_owner: boolean;
  pack_time: number;
  can_pack: boolean;
};

export const TentController = (props) => {
  const { act, data } = useBackend<Data>();
  const packSeconds = Math.round(data.pack_time / 10) / 10;

  return (
    <Window width={320} height={180}>
      <Window.Content>
        <Section title="Tent Controller">
          <LabeledList>
            <LabeledList.Item label="Owner">
              {data.owner_name}
            </LabeledList.Item>
            <LabeledList.Item label="Packing time">
              {packSeconds} seconds
            </LabeledList.Item>
          </LabeledList>
          <Button
            mt={2}
            fluid
            icon="box"
            disabled={!data.can_pack}
            onClick={() => act('pack')}
          >
            Pack tent
          </Button>
        </Section>
      </Window.Content>
    </Window>
  );
};
