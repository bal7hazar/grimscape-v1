// Core imports

use core::debug::PrintTrait;

// Inernal imports

use grimscape::constants::{SPELL_BIT_LENGTH, TEAM_MATE_COUNT};
use grimscape::models::index::Team;
use grimscape::types::direction::Direction;
use grimscape::types::role::{Role, RoleTrait};
use grimscape::types::spell::Spell;
use grimscape::types::element::{Element, ElementTrait};
use grimscape::helpers::deck::{Deck, DeckTrait};
use grimscape::helpers::bitmap::Bitmap;
use grimscape::helpers::seeder::Seeder;
use grimscape::helpers::packer::Packer;
use grimscape::helpers::dice::{Dice, DiceTrait};

mod errors {
    const TEAM_NOT_EXIST: felt252 = 'Team: does not exist';
    const TEAM_ALREADY_EXIST: felt252 = 'Team: already exist';
    const TEAM_INVALID_DIRECTION: felt252 = 'Team: invalid direction';
    const TEAM_IS_DEAD: felt252 = 'Team: is dead';
}

#[generate_trait]
impl TeamImpl of TeamTrait {
    #[inline]
    fn new(dungeon_id: u32, id: u32, seed: felt252, player_id: felt252) -> Team {
        // [Compute] Default deck
        let spells: Array<u8> = array![
            Spell::Kick.into(),
            Spell::Kick.into(),
            Spell::Kick.into(),
            Spell::Heal.into(),
            Spell::Heal.into(),
            Spell::Heal.into(),
        ];
        let deck: u64 = Packer::pack(spells, SPELL_BIT_LENGTH);
        // [Return] Team
        Team { dungeon_id, id, x: 0, y: 0, dead: false, deck, spells: 0, seed, player_id, }
    }

    #[inline]
    fn spells(self: Team) -> Array<u8> {
        Packer::unpack(self.spells, SPELL_BIT_LENGTH)
    }

    #[inline]
    fn spell_at(self: Team, index: u8) -> Spell {
        let spell: u8 = Packer::get(self.spells, index, SPELL_BIT_LENGTH);
        spell.into()
    }

    #[inline]
    fn mint(ref self: Team, spell: Spell) {
        let mut spells: Array<u8> = Packer::unpack(self.deck, SPELL_BIT_LENGTH);
        spells.append(spell.into());
        self.deck = Packer::pack(spells, SPELL_BIT_LENGTH);
    }

    #[inline]
    fn burn(ref self: Team, index: u8) {
        self.deck = Packer::remove_at(self.deck, index, SPELL_BIT_LENGTH);
    }

    #[inline]
    fn pick_spells(ref self: Team, seed: felt252) {
        // [Compute] Spells
        let mut spells: Array<u8> = Packer::unpack(self.deck, SPELL_BIT_LENGTH);
        let count = spells.len();
        let mut deck: Deck = DeckTrait::new(seed, count);
        let spells = array![
            *spells.at(deck.draw().into() - 1),
            *spells.at(deck.draw().into() - 1),
            *spells.at(deck.draw().into() - 1),
        ];
        // [Effect] Update spells
        self.spells = Packer::pack(spells, SPELL_BIT_LENGTH);
    }

    #[inline]
    fn move(ref self: Team, direction: Direction) {
        // [Check] Direction is valid
        let direction_id: u8 = direction.into();
        assert(direction_id != Direction::None.into(), errors::TEAM_INVALID_DIRECTION);
        // [Effect] Update position
        match direction {
            Direction::North => { self.y += 1; },
            Direction::East => { self.x += 1; },
            Direction::South => { self.y -= 1; },
            Direction::West => { self.x -= 1; },
            _ => {},
        }
        // [Effect] Reseed
        self.seed = Seeder::reseed(self.seed, direction_id.into());
    }

    #[inline]
    fn clean(ref self: Team) {
        self.spells = 0;
    }

    #[inline]
    fn compute_mates(self: Team) -> Array<(Role, Element)> {
        // [Compute] Mate atributes and distribution
        let mut dice: Dice = DiceTrait::new(RoleTrait::count(), self.seed);
        let mut mates: Array<(Role, Element)> = array![];
        let mut count = TEAM_MATE_COUNT;
        loop {
            if count == 0 {
                break;
            };
            dice.face_count = RoleTrait::count();
            let role: Role = dice.roll().into();
            dice.face_count = ElementTrait::count();
            let element: Element = dice.roll().into();
            mates.append((role, element));
            count -= 1;
        };
        mates
    }
}

#[generate_trait]
impl TeamAssert of AssertTrait {
    #[inline]
    fn assert_exists(self: Team) {
        assert(0 != self.seed && !self.dead, errors::TEAM_NOT_EXIST);
    }

    #[inline]
    fn assert_not_exists(self: Team) {
        assert(0 == self.seed || self.dead, errors::TEAM_ALREADY_EXIST);
    }

    #[inline]
    fn assert_not_dead(self: Team) {
        assert(!self.dead, errors::TEAM_IS_DEAD);
    }
}

#[cfg(test)]
mod tests {
    // Core imports

    use core::debug::PrintTrait;

    // Local imports

    use super::{Team, TeamTrait, Direction, Spell};

    // Constants

    const DUNGEON_ID: u32 = 1;
    const TEAM_ID: u32 = 42;
    const SEED: felt252 = 'SEED';
    const PLAYER_ID: felt252 = 'PLAYER';

    #[test]
    fn test_team_new() {
        let team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        assert_eq!(team.dungeon_id, DUNGEON_ID);
        assert_eq!(team.id, TEAM_ID);
        assert_eq!(team.x, 0);
        assert_eq!(team.y, 0);
        assert_eq!(team.dead, false);
        assert_eq!(team.seed, SEED);
    }

    #[test]
    fn test_team_move_north() {
        let mut team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        let seed = team.seed;
        team.move(Direction::North);
        assert_eq!(seed != team.seed, true);
        assert_eq!(team.y, 1);
        assert_eq!(team.x, 0);
    }

    #[test]
    fn test_team_move_east() {
        let mut team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        let seed = team.seed;
        team.move(Direction::East);
        assert_eq!(seed != team.seed, true);
        assert_eq!(team.y, 0);
        assert_eq!(team.x, 1);
    }

    #[test]
    fn test_team_move_south() {
        let mut team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        let seed = team.seed;
        team.move(Direction::South);
        assert_eq!(seed != team.seed, true);
        assert_eq!(team.y, -1);
        assert_eq!(team.x, 0);
    }

    #[test]
    fn test_team_move_west() {
        let mut team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        let seed = team.seed;
        team.move(Direction::West);
        assert_eq!(seed != team.seed, true);
        assert_eq!(team.y, 0);
        assert_eq!(team.x, -1);
    }

    #[test]
    fn test_team_pick_spells() {
        let mut team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        assert_eq!(team.spells, 0);
        team.pick_spells(team.seed);
        assert_eq!(team.spells, 0x332);
    }

    #[test]
    fn test_team_mint_pick_spells() {
        let mut team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        assert_eq!(team.spells, 0);
        team.mint(Spell::Fireball);
        assert_eq!(team.deck, 0x7333222);
        team.pick_spells(team.seed);
        assert_eq!(team.spells, 0x723);
    }

    #[test]
    fn test_team_burn_pick_spells() {
        let mut team = TeamTrait::new(DUNGEON_ID, TEAM_ID, SEED, PLAYER_ID);
        assert_eq!(team.spells, 0);
        team.burn(3);
        assert_eq!(team.deck, 0x33222);
        team.pick_spells(team.seed);
        assert_eq!(team.spells, 0x232);
    }
}

