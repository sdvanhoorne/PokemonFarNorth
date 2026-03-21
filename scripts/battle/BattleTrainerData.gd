class_name BattleTrainerData
extends RefCounted

var trainer_id: String
var display_name: String
var party: Array
var intro_lines: Array[String]
var outro_lines_win: Array[String]
var outro_lines_lose: Array[String]
var portrait: Texture2D

static func from_trainer(trainer: Trainer) -> BattleTrainerData:
	var data := BattleTrainerData.new()
	data.trainer_id = trainer.npc_id
	data.display_name = trainer.npc_name
	data.party = trainer.party.duplicate(true)
	data.intro_lines = trainer.intro_lines.duplicate()
	data.outro_lines_win = trainer.outro_lines_win.duplicate()
	data.outro_lines_lose = trainer.outro_lines_lose.duplicate()
	data.portrait = trainer.portrait
	return data
