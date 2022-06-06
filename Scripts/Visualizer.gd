extends Node
signal clicked(node)

export var pieces_path : NodePath
onready var pieces = get_node(pieces_path)
var white_piece = preload("res://Scenes/White Piece.tscn")
var black_piece = preload("res://Scenes/Black Piece.tscn")

var circle1 = [21,22,31,39,38,29]
var circle2 = [13,14,15,23,32,40,47,46,45,37,28,20]
var circle3 = [6,7,8,9,16,24,33,41,48,54,53,52,51,44,36,27,19,12]
var circle4 = [0,1,2,3,4,10,17,25,34,42,49,55,60,59,58,57,56,50,43,35,26,18,11,5]
var weight = [-1000,100,5,1000]
var state
var turn
var transposition = []
var history = []
var history_len = 0
var turn_to_show = 0
var state_history = state
var player_moves_len = 0
var player_state = state
var player_state_choosed_number = 0
var possible_player_states = []
var finished = false
var playersubmit = false
var computermove = false
func _ready():
	draw_complete_board(BoardManager.current_board)
	var first_board = BoardManager.current_board
	state = State.new(first_board, 0,0)
	turn = 1


#func _process(delta):
#	if not finished:
#		transposition.append(state.board)
#		state = min_max_search(state, 2, turn)
#		update_board(state.board)
#		turn = 3 - turn 
#		history.append(state)
#		state_history = state
#	if state.white_score == 6 or state.black_score == 6 or finished:
#		if not finished: 
#			history_len = len(history)
#			turn_to_show = history_len
#		update_board(state_history.board)
#		finished = true
func _process(delta):
	if not finished:
		if turn == 2:
			transposition.append(state.board)
			state = min_max_search(state, 2, turn)
			update_board(state.board)
			turn = 3 - turn 
			history.append(state)
			state_history = state
		if turn == 1:
			if not computermove:
				if playersubmit:
					player_state_choosed_number = 0
					possible_player_states = Successor.calculate_successor(state, turn)
					player_moves_len == len(possible_player_states)
					history.append(state)
					state_history = state
					playersubmit = false
				yield(self, "playermove")
				state = player_state
				update_board(state.board)
			if computermove:
				transposition.append(state.board)
				state = min_max_search(state, 2, turn)
				update_board(state.board)
				turn = 3 - turn 
				history.append(state)
				state_history = state
				computermove = false
#		yield(self, "playersubmit")
	if state.white_score == 6 or state.black_score == 6 or finished:
		if not finished: 
			history_len = len(history)
			turn_to_show = history_len
		update_board(state_history.board)
		finished = true
signal playermove
func _input(ev):
	if ev is InputEventKey and ev.scancode == KEY_RIGHT and finished:
		if turn_to_show < history_len-1:
			turn_to_show += 1
			state_history = history[turn_to_show]
			set_process(true)
	if ev is InputEventKey and ev.scancode == KEY_LEFT and finished:
		if turn_to_show >= 0:
			turn_to_show -= 1
			state_history = history[turn_to_show]
			set_process(true)
	if ev is InputEventKey and ev.scancode == KEY_D and not finished:
		player_state_choosed_number += 1
		player_state =  possible_player_states[player_state_choosed_number]
		set_process(true)
		emit_signal("playermove")
	if ev is InputEventKey and ev.scancode == KEY_A and not finished:
		player_state_choosed_number -= 1
		player_state =  possible_player_states[player_state_choosed_number]
		set_process(true)
		emit_signal("playermove")
	if ev is InputEventKey and ev.scancode == KEY_ENTER and not finished:
		emit_signal("playersubmit")
	
func get_heuristic(piece, board):
	var result = 0
	var pieces = get_pieces(piece, board)
	var enemy_pieces = get_pieces(3 - piece, board)
	result += weight[1] * enemy_center_distance(enemy_pieces)
	result += weight[2] * center_distance(pieces)
	result += weight[3] * kill(enemy_pieces)
	return result
func kill(marbles):
	return 14 - len(marbles)
func enemy_center_distance(marbles_opp):
	var result = 0
	for p in marbles_opp: 
		if p in circle1:
			result += 1
		elif p in circle2:
			result += 2
		elif p in circle3:
			result += 3
		elif p in circle4:
			result += 4
		else :
			result += 0
	return result
func center_distance(marbles):
	var result = 0
	for p in marbles: 
		if p in circle1:
			result += 4
		elif p in circle2:
			result += 3
		elif p in circle3:
			result += 2
		elif p in circle4:
			result += 1
		else :
			result += 5
	return result

func get_pieces(piece, board):
	var indexes = []
	for index in range(len(board)):
		if board[index] == piece:
			indexes.append(index)
	return indexes
func transposition_table(moves):
	var filtered_moves = []
	for move in moves:
		if transposition.has(move.board):
			continue
		filtered_moves.append(move)
	return filtered_moves
#beam search 
func delete_stupid_moves(moves, current_state, turn):
	var smart_moves = []
	for move in moves:
		if turn == 1:
			if move.white_score >= current_state.white_score:
				smart_moves.append(move)
		elif turn == 2:
			if move.black_score >= current_state.black_score:
				smart_moves.append(move)
	var final_moves = bublesort_moves(turn, smart_moves)
	return final_moves
func bublesort_moves(turn,moves):
	for move in moves: 
		move.heuristic_score = get_heuristic(turn ,move.board)
	var n = len(moves)
	for i in range(n):
		for j in range(0, n - i - 1):
			if moves[j].heuristic_score < moves[j+1].heuristic_score:
				var movej = moves[j]
				moves[j] = moves[j+1]
				moves[j+1] = moves[j]
	return moves
	
func min_max_search(state, depth, turn):
	var next_state
	next_state = max_value(state, depth, turn, -99999999999999, 9999999999999)
	return next_state

func max_value(state, depth, turn, alpha, beta):
	if state.black_score == 6 or state.white_score == 6 or depth <= 0:
		return state
	var legal_moves
	legal_moves = Successor.calculate_successor(state, turn)
	var legal_move_filtered = transposition_table(legal_moves)
	var smart_moves = delete_stupid_moves(legal_move_filtered, state, turn)
	for move in smart_moves:
		var min_state = min_value(move, depth-1, turn, alpha, beta)
		if  move.heuristic_score >= beta:
			state = move
			return state
		elif move.heuristic_score > alpha:
			state = move
			alpha = move.heuristic_score
	return state

func min_value(state, depth, turn, alpha, beta):
	if state.black_score == 6 or state.white_score == 6 or depth <= 0:
		return state
	var legal_moves
	legal_moves = Successor.calculate_successor(state, turn)
	var legal_move_filtered = transposition_table(legal_moves)
	var smart_moves = delete_stupid_moves(legal_move_filtered, state, turn)
	for move in smart_moves:
		var max_state = max_value(move, depth-1, turn, alpha, beta)
		if  move.heuristic_score <= alpha:
			state = move
			return state
		elif move.heuristic_score < beta:
			state = move
			beta = move.heuristic_score
	return state

func update_board(new_board):
	for child in pieces.get_children():
		child.queue_free()
	draw_complete_board(new_board)

func draw_complete_board(board):
	var coordinates = Vector3(0, 0, 0)
	for cell_number in range(len(board)):
		if board[cell_number] == BoardManager.WHITE:
			coordinates = get_3d_coordinates(cell_number)
			var piece = white_piece.instance()
			pieces.add_child(piece)
			piece.translation = coordinates
		elif board[cell_number] == BoardManager.BLACK:
			coordinates = get_3d_coordinates(cell_number)
			var piece = black_piece.instance()
			pieces.add_child(piece)
			piece.translation = coordinates

func get_3d_coordinates(cell_number):
	if cell_number >= 0 and cell_number <= 4:
		return Vector3(-0.6 + cell_number * 0.3, 0.01, -1.04)
	elif cell_number >= 5 and cell_number <= 10:
		return Vector3(-0.75 + (cell_number - 5) * 0.3, 0.01, -0.78)
	elif cell_number >= 11 and cell_number <= 17:
		return Vector3(-0.9 + (cell_number - 11) * 0.3, 0.01, -0.52)
	elif cell_number >= 18 and cell_number <= 25:
		return Vector3(-1.05 + (cell_number - 18) * 0.3, 0.001, -0.26)
	elif cell_number >= 26 and cell_number <= 34:
		return Vector3(-1.2 + (cell_number - 26) * 0.3, 0.01, 0)
	elif cell_number >= 35 and cell_number <= 42:
		return Vector3(-1.05 + (cell_number - 35) * 0.3, 0.01, 0.26)
	elif cell_number >= 43 and cell_number <= 49:
		return Vector3(-0.9 + (cell_number - 43) * 0.3, 0.01, 0.52)
	elif cell_number >= 50 and cell_number <= 55:
		return Vector3(-0.75 + (cell_number - 50) * 0.3, 0.01, 0.78)
	else:
		return Vector3(-0.6 + (cell_number - 56) * 0.3, 0.01, 1.04)
	


func _on_Button_pressed():
	playersubmit = true
	turn = 3 - turn 
	set_process(true)


func _on_Button2_pressed():
	computermove = true
