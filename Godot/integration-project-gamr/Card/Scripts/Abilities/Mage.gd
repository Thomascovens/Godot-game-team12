extends Node

const DAMAGE = 3
const AMOUNT_OF_CARDS = 2 

func trigger_ability(defending_cards):
	var defending_cards_repl = defending_cards
	var cards_to_destroy = []
	for i in range(AMOUNT_OF_CARDS):
		var defending_card = defending_cards_repl.pick_random()
		if defending_card:
			defending_card.health = max(0,defending_card.health - DAMAGE)
			if defending_card.health == 0:
				cards_to_destroy.append(defending_card)
				defending_cards_repl.erase(defending_card)
	return cards_to_destroy
