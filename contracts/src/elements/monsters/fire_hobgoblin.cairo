// Internal imports

use rpg::elements::monsters::interface::{MonsterTrait, Spell, Element};

impl FireHobgoblin of MonsterTrait {
    #[inline]
    fn health() -> u8 {
        200
    }

    #[inline]
    fn spell() -> Spell {
        Spell::DamageAll
    }

    #[inline]
    fn element() -> Element {
        Element::Fire
    }
}