const CARDS = { #attack,health,cost,cardType,abilityText,abilityScript,defence,focus,rage
	"Knight": [2,3,3, "Unit","Defend",null,true,false,false],
	"Soldier": [4,2,1, "Unit","",null,true,false,false],
	"MageSoldier":[3,1,2, "Unit","",false,false,false,false],
	"Mage": [2,2,3, "Unit","3 damage to 2 random enemies","res://Card/Scripts/Abilities/Mage.gd",false,false,false],
	"General": [5,7,4, "Unit","Rage",null,false,false,true],
	"Tornado": [null, null,4, "Magic","Deal 2 damage to all enemy cards","res://Card/Scripts/Abilities/Tornado.gd",false,false,false],
	"Assassin": [10,1,2,"Unit","Focus",null,false,true,false],
	"Lightning": [null, null, 3, "Magic","Half damage of enemy cards", "res://Card/Scripts/Abilities/Lightning.gd",false,false,false],
	"Sword": [null, null, 3, "Magic","5 Damage, on kill gain 3 hp", "res://Card/Scripts/Abilities/Sword.gd",false,false,false],
	"Fireball": [null, null, 3, "Magic","Do 3 Damage to opponent", "res://Card/Scripts/Abilities/Fireball.gd",false,false,false],
}
