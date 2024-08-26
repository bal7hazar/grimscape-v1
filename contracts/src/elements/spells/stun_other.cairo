// Internal imports

use rpg::elements::spells::interface::{SpellTrait, Mob, MobTrait};

// Constants

const STUN: u8 = 1;

impl StunOther of SpellTrait {
    #[inline]
    fn apply(ref caster: Mob, ref target: Mob, ref mates: Array<Mob>, ref foes: Array<Mob>) {
        let mut index = foes.len();
        loop {
            if index == 0 {
                break;
            }
            let mut foe = foes.pop_front().unwrap();
            foe.stun(STUN);
            foes.append(foe);
            index -= 1;
        };
        caster.debuff();
    }
}
